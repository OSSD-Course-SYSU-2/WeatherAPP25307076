import http from '@ohos.net.http';
import common from '@ohos.app.ability.common';
import { BusinessError } from '@kit.BasicServicesKit';
import { OpenLinkOptions } from '@kit.AbilityKit';
import router from '@ohos.router';

// ---------- 类型定义 ----------
interface LivesItem {
  temperature: string;
  weather: string;
  humidity: string;
  winddirection: string;
  windpower: string;
  reporttime: string;
}

interface WeatherApiResponse {
  status: string;
  count: string;
  info: string;
  infocode: string;
  lives?: LivesItem[];
}

interface CastItem {
  date: string;
  week: string;
  dayweather: string;
  nightweather: string;
  daytemp: string;
  nighttemp: string;
  daywind: string;
  nightwind: string;
  daypower: string;
  nightpower: string;
}

interface ForecastData {
  city: string;
  adcode: string;
  province: string;
  reporttime: string;
  casts: CastItem[];
}

interface WeatherAllResponse {
  status: string;
  count: string;
  info: string;
  infocode: string;
  forecasts?: ForecastData[];
}

interface CityPoiItem {
  id: string;
  name: string;
  type: string;
  typecode: string;
  address: string;
  location: string;
  adcode: string;
}

interface CitySearchResponse {
  status: string;
  count: string;
  info: string;
  infocode: string;
  tips?: CityPoiItem[];
}

interface HourForecastItem {
  time: string;
  temp: string;
  weather: string;
}

interface WebPageParams {
  url: string;
  title: string;
}

// ---------- 常量数据 ----------
const CAPITAL_CITIES: string[] = [
  '北京', '上海', '天津', '重庆',
  '哈尔滨', '长春', '沈阳', '呼和浩特', '乌鲁木齐', '拉萨',
  '西宁', '兰州', '银川', '西安', '太原', '石家庄', '郑州',
  '济南', '合肥', '武汉', '南京', '成都', '贵阳', '昆明',
  '南宁', '广州', '福州', '南昌', '长沙', '杭州', '海口',
  '香港', '澳门', '台北'
];

// ---------- 主组件 ----------
@Entry
@Component
struct WeatherApp {
  @State city: string = '北京';
  @State temperature: string = '--°C';
  @State weatherDesc: string = '加载中...';
  @State humidity: string = '';
  @State wind: string = '';
  @State aqi: string = '';
  @State aqiQuality: string = '';
  @State pm25: string = '';
  @State hourForecast: HourForecastItem[] = [];
  @State showSearchDialog: boolean = false;
  @State searchKeyword: string = '';
  @State searchResults: CityPoiItem[] = [];
  @State isSearching: boolean = false;
  private apiKey: string = '69ca5ebc03ec8054e0c0a7f2dd3082d0';

  // ---------- 工具方法 ----------
  getCityEmoji(cityName: string): string {
    const cityEmojiMap: Record<string, string> = {
      '北京': '🏯',
      '上海': '🗼',
      '广州': '🏙️',
      '成都': '🐼',
      '武汉': '🌉',
      '西安': '🏛️',
      '沈阳': '🏭',
      '昆明': '🌸',
      '乌鲁木齐': '🍇',
      '拉萨': '🏔️',
      '哈尔滨': '❄️',
      '香港': '🌃',
      '澳门': '🎰',
      '台北': '🗼',
    };
    return cityEmojiMap[cityName] || '🏙️';
  }

  getWeatherEmoji(text: string): string {
    const lowerText: string = text.toLowerCase();
    if (lowerText.includes('晴')) return '☀️';
    if (lowerText.includes('多云')) return '⛅';
    if (lowerText.includes('阴')) return '☁️';
    if (lowerText.includes('雷')) return '⛈️';
    if (lowerText.includes('暴雨') || lowerText.includes('大雨')) return '🌧️';
    if (lowerText.includes('中雨')) return '🌧️';
    if (lowerText.includes('小雨')) return '🌦️';
    if (lowerText.includes('阵雨')) return '🌦️';
    if (lowerText.includes('雨夹雪')) return '🌨️';
    if (lowerText.includes('雨')) return '🌧️';
    if (lowerText.includes('雪')) return '❄️';
    if (lowerText.includes('雾') || lowerText.includes('霾')) return '🌫️';
    if (lowerText.includes('风')) return '💨';
    if (lowerText.includes('沙')) return '🌪️';
    return '🌡️';
  }

  getHostContext(): common.UIAbilityContext {
    return getContext(this) as common.UIAbilityContext;
  }

  // ---------- 天气数据 ----------
  async getWeather(): Promise<void> {
    await Promise.all([this.getRealtimeWeather(), this.getForecast()]);
  }

  async getRealtimeWeather(): Promise<void> {
    let httpRequest = http.createHttp();
    try {
      const url: string =
        `https://restapi.amap.com/v3/weather/weatherInfo?key=${this.apiKey}&city=${encodeURIComponent(this.city)}`;
      let response = await httpRequest.request(url, {
        method: http.RequestMethod.GET,
        expectDataType: http.HttpDataType.STRING,
        connectTimeout: 10000,
        readTimeout: 10000
      });
      let resultStr: string = response.result as string;
      let data: WeatherApiResponse = JSON.parse(resultStr) as WeatherApiResponse;
      if (data.status === '1' && data.lives && data.lives.length > 0) {
        const live: LivesItem = data.lives[0];
        this.temperature = `${live.temperature}°C`;
        this.weatherDesc = live.weather;
        this.humidity = `${live.humidity}%`;
        this.wind = `${live.winddirection} ${live.windpower}级`;
      } else {
        this.weatherDesc = '获取失败';
      }
    } catch (e) {
      this.weatherDesc = '请求失败';
    } finally {
      httpRequest.destroy();
    }
  }

  async getForecast(): Promise<void> {
    let httpRequest = http.createHttp();
    try {
      const url: string =
        `https://restapi.amap.com/v3/weather/weatherInfo?key=${this.apiKey}&city=${encodeURIComponent(this.city)}&extensions=all`;
      let response = await httpRequest.request(url, {
        method: http.RequestMethod.GET,
        expectDataType: http.HttpDataType.STRING,
        connectTimeout: 10000,
        readTimeout: 10000
      });
      let resultStr: string = response.result as string;
      let data: WeatherAllResponse = JSON.parse(resultStr) as WeatherAllResponse;
      if (data.status === '1' && data.forecasts && data.forecasts.length > 0) {
        const forecast: ForecastData = data.forecasts[0];
        const casts: CastItem[] = forecast.casts;
        if (casts && casts.length > 0) {
          const nowHour: number = new Date().getHours();
          const forecastList: HourForecastItem[] = [];
          for (let i: number = 0; i < Math.min(2, casts.length); i++) {
            const cast: CastItem = casts[i];
            const isDay: boolean = nowHour >= 6 && nowHour < 18;
            const temp: string = isDay ? cast.daytemp : cast.nighttemp;
            const weather: string = isDay ? cast.dayweather : cast.nightweather;
            const timeLabel: string = i === 0 ? '今天' : '明天';
            forecastList.push({
              time: timeLabel,
              temp: temp + '°C',
              weather: weather
            });
          }
          this.hourForecast = forecastList;
        }
      }
    } catch (e) {
      console.error('预报请求失败');
    } finally {
      httpRequest.destroy();
    }
  }

  // ---------- 城市搜索 ----------
  async searchCity(keyword: string): Promise<void> {
    if (!keyword || keyword.trim().length === 0) {
      this.searchResults = [];
      return;
    }
    this.isSearching = true;
    let httpRequest = http.createHttp();
    try {
      const url: string =
        `https://restapi.amap.com/v3/assistant/inputtips?key=${this.apiKey}&keywords=${encodeURIComponent(keyword)}&city=&citylimit=false&datatype=all`;
      let response = await httpRequest.request(url, {
        method: http.RequestMethod.GET,
        expectDataType: http.HttpDataType.STRING,
        connectTimeout: 10000,
        readTimeout: 10000
      });
      let resultStr: string = response.result as string;
      let data: CitySearchResponse = JSON.parse(resultStr) as CitySearchResponse;
      if (data.status === '1' && data.tips && data.tips.length > 0) {
        this.searchResults = data.tips.filter((item: CityPoiItem) => {
          return item.typecode?.startsWith('19') ||
          item.name.includes('市') || item.name.includes('区') ||
          item.name.includes('县') || item.name.includes('州');
        });
        if (this.searchResults.length === 0) {
          this.searchResults = data.tips.slice(0, 5);
        }
      } else {
        this.searchResults = [];
      }
    } catch (e) {
      this.searchResults = [];
    } finally {
      this.isSearching = false;
      httpRequest.destroy();
    }
  }

  selectCity(cityName: string): void {
    this.city = cityName;
    this.showSearchDialog = false;
    this.searchKeyword = '';
    this.searchResults = [];
    this.getWeather();
  }

  // ---------- 网页跳转 ----------
  openWebPage(url: string, title: string): void {
    const params: WebPageParams = { url, title };
    router.pushUrl({
      url: 'pages/WebViewPage',
      params
    }).catch((err: Error) => {
      console.error('跳转失败: ' + err.message);
    });
  }

  async openBaiduWeather(): Promise<void> {
    let url: string = `https://www.baidu.com/s?wd=${encodeURIComponent(this.city + '天气')}`;
    let context: common.UIAbilityContext = this.getHostContext();
    let openLinkOptions: OpenLinkOptions = { appLinkingOnly: false };
    try {
      await context.openLink(url, openLinkOptions);
    } catch (err) {
      let e: BusinessError = err as BusinessError;
      console.error(`打开链接失败: ${e.message}`);
    }
  }

  // ---------- UI 构建 ----------
  build() {
    Stack() {
      Column() {
        // ========== 固定头部（不滚动） ==========
        // 搜索栏
        Row() {
          TextInput({ placeholder: '输入城市名', text: this.city })
            .onChange((value: string) => {
              this.city = value;
            })
            .onSubmit(() => {
              this.getWeather();
            })
            .layoutWeight(1)
            .height(48)
            .backgroundColor('#1E2430')
            .borderRadius(24)
            .padding({ left: 16, right: 16 })
            .fontColor('#FFFFFF')
            .placeholderColor('#8899AA');

          Button('🔍')
            .width(48)
            .height(48)
            .fontSize(20)
            .backgroundColor('#6C5CE7')
            .fontColor(Color.White)
            .borderRadius(24)
            .margin({ left: 8 })
            .shadow({ radius: 8, color: '#6C5CE750', offsetY: 4 })
            .onClick(() => {
              this.showSearchDialog = true;
              this.searchKeyword = '';
              this.searchResults = [];
            });
        }
        .width('100%')
        .padding({ left: 16, right: 16 })
        .margin({ top: 20, bottom: 16 });

        // 天气卡片（科幻深海渐变）
        // 天气卡片（缩小版）
        Column() {
          Row() {
            Text(this.getCityEmoji(this.city))
              .fontSize(24)
              .margin({ right: 6 });
            Text(this.city)
              .fontSize(22)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FFFFFF');
          }
          .width('100%')
          .margin({ bottom: 4 });

          Text(this.getWeatherEmoji(this.weatherDesc))
            .fontSize(56)
            .margin({ bottom: 4 });

          Text(this.temperature)
            .fontSize(48)
            .fontWeight(FontWeight.Lighter)
            .fontColor('#FFFFFF')
            .margin({ bottom: 2 });

          Text(this.weatherDesc)
            .fontSize(16)
            .fontColor('#FFFFFF')
            .opacity(0.9)
            .margin({ bottom: 12 });

          Row() {
            Row() {
              Text('💧').fontSize(14).margin({ right: 4 });
              Text(this.humidity).fontSize(13).fontWeight(FontWeight.Medium).fontColor('#FFFFFF');
            }
            .padding({ left: 12, right: 12, top: 6, bottom: 6 })
            .backgroundColor('#1E243080')
            .borderRadius(16)
            .backdropBlur(4);

            Row() {
              Text('🌬️').fontSize(14).margin({ right: 4 });
              Text(this.wind).fontSize(13).fontWeight(FontWeight.Medium).fontColor('#FFFFFF');
            }
            .padding({ left: 12, right: 12, top: 6, bottom: 6 })
            .backgroundColor('#1E243080')
            .borderRadius(16)
            .backdropBlur(4)
            .margin({ left: 10 });
          }
          .width('100%')
          .margin({ bottom: 10 });

          Divider().strokeWidth(1).color('#FFFFFF30').margin({ top: 6, bottom: 10 });

          Text('📅 未来两天')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor('#FFFFFF')
            .opacity(0.9)
            .margin({ bottom: 8 })
            .alignSelf(ItemAlign.Start);

          if (this.hourForecast.length > 0) {
            Row() {
              ForEach(this.hourForecast, (item: HourForecastItem) => {
                Column() {
                  Text(item.time)
                    .fontSize(12)
                    .fontWeight(FontWeight.Medium)
                    .fontColor('#FFFFFF')
                    .margin({ bottom: 4 });
                  Text(this.getWeatherEmoji(item.weather))
                    .fontSize(24)
                    .margin({ bottom: 4 });
                  Text(item.temp)
                    .fontSize(15)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#FFFFFF')
                    .margin({ bottom: 2 });
                  Text(item.weather)
                    .fontSize(11)
                    .fontColor('#FFFFFF')
                    .opacity(0.8)
                    .maxLines(1);
                }
                .width('48%')
                .padding({ top: 10, bottom: 10, left: 6, right: 6 })
                .backgroundColor('#1E243080')
                .borderRadius(16)
                .backdropBlur(8)
                .margin({ right: 6 })
              });
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceBetween);
          }
        }
        .padding({ top: 16, bottom: 16, left: 20, right: 20 })
        .width('100%')
        .borderRadius(28)
        .linearGradient({
          angle: 135,
          colors: [['#1e3c72', 0.0], ['#2a5298', 1.0]]
        })
        .shadow({ radius: 20, color: '#1e3c7250', offsetY: 10 })
        .margin({ left: 16, right: 16, bottom: 12 });
        // ========== 可滚动内容 ==========
        Scroll() {
          Column() {
            // 省会城市快捷入口
            Text('📍 省会城市快捷入口')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor('#FFFFFF')
              .margin({ top: 8, left: 16, bottom: 8 })
              .alignSelf(ItemAlign.Start);

            Grid() {
              ForEach(CAPITAL_CITIES, (cityName: string) => {
                GridItem() {
                  Button(cityName)
                    .width('100%')
                    .height(40)
                    .fontSize(14)
                    .backgroundColor('#1E2430')
                    .fontColor('#FFFFFF')
                    .borderRadius(20)
                    .onClick(() => {
                      this.city = cityName;
                      this.getWeather();
                    });
                }
              });
            }
            .columnsTemplate('1fr 1fr 1fr 1fr')
            .rowsGap(10)
            .columnsGap(10)
            .padding({ left: 16, right: 16 })
            .margin({ bottom: 16 });

            // 卫星云图入口
            Row() {
              Text('🛰️ 卫星云图')
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor('#FFFFFF');
              Blank();
              Button('查看实时云图')
                .fontSize(14)
                .height(32)
                .backgroundColor('#6C5CE7')
                .fontColor(Color.White)
                .borderRadius(16)
                .padding({ left: 16, right: 16 })
                .shadow({ radius: 8, color: '#6C5CE750', offsetY: 4 })
                .onClick(() => {
                  this.openWebPage('http://www.nmc.cn/publish/observations/satellite/fy2g-ir1.html', '实时卫星云图');
                });
            }
            .width('100%')
            .padding({ left: 16, right: 16 })
            .margin({ top: 20, bottom: 8 });

            Column() {
              Row() {
                Text('🛰️').fontSize(40).margin({ right: 12 });
                Column() {
                  Text('中央气象台官方云图')
                    .fontSize(15)
                    .fontWeight(FontWeight.Medium)
                    .fontColor('#FFFFFF')
                    .margin({ bottom: 4 });
                  Text('红外云图 · 风云二号卫星').fontSize(12).fontColor('#AABBCC').margin({ bottom: 2 });
                  Text('点击查看实时动态云图').fontSize(11).fontColor('#6C5CE7');
                }.alignItems(HorizontalAlign.Start);
              }
              .width('100%')
              .padding(16);
            }
            .width('100%')
            .linearGradient({ angle: 135, colors: [['#2b1b54', 0.0], ['#1a1a2e', 1.0]] })
            .borderRadius(16)
            .margin({ left: 16, right: 16 })
            .onClick(() => {
              this.openWebPage('http://www.nmc.cn/publish/observations/satellite/fy2g-ir1.html', '实时卫星云图');
            });

            // 专业气象服务
            Text('🌐 专业气象服务')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor('#FFFFFF')
              .margin({ top: 24, left: 16, bottom: 8 })
              .alignSelf(ItemAlign.Start);

            Row() {
              Column() {
                Button('🇨🇳 时局图')
                  .width('100%')
                  .height(44)
                  .fontSize(14)
                  .backgroundColor('#1E2430')
                  .fontColor('#FFFFFF')
                  .borderRadius(22)
                  .onClick(() => this.openWebPage('https://www.weather.com.cn/static/html/product_wxyt.shtml',
                    '中国天气网云图'));
                Text('国家气象局').fontSize(11).fontColor('#8899AA').margin({ top: 4 });
              }.width('30%').alignItems(HorizontalAlign.Center);

              Column() {
                Button('🌍 Ventusky')
                  .width('100%')
                  .height(44)
                  .fontSize(14)
                  .backgroundColor('#1E2430')
                  .fontColor('#FFFFFF')
                  .borderRadius(22)
                  .onClick(() => this.openWebPage('https://www.ventusky.com', 'Ventusky'));
                Text('全球风图/气压').fontSize(11).fontColor('#8899AA').margin({ top: 4 });
              }.width('30%').alignItems(HorizontalAlign.Center);

              Column() {
                Button('💨 Windy')
                  .width('100%')
                  .height(44)
                  .fontSize(14)
                  .backgroundColor('#1E2430')
                  .fontColor('#FFFFFF')
                  .borderRadius(22)
                  .onClick(() => this.openWebPage('https://www.windy.com', 'Windy'));
                Text('全球气象可视化').fontSize(11).fontColor('#8899AA').margin({ top: 4 });
              }.width('30%').alignItems(HorizontalAlign.Center);
            }
            .width('100%')
            .padding({ left: 16, right: 16 })
            .justifyContent(FlexAlign.SpaceBetween)
            .margin({ bottom: 16 });

            // 百度天气
            Button('🌐 访问百度天气网站')
              .width('90%')
              .height(56)
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .backgroundColor('#6C5CE7')
              .fontColor(Color.White)
              .borderRadius(28)
              .shadow({ radius: 16, color: '#6C5CE750', offsetY: 6 })
              .margin({ top: 8, bottom: 30 })
              .onClick(() => this.openBaiduWeather());
          }
          .width('100%');
        }
        .scrollable(ScrollDirection.Vertical)
        .scrollBar(BarState.Auto)
        .layoutWeight(1) // 占据剩余高度，实现滚动
      }
      .width('100%')
      .height('100%');

      // 城市搜索弹窗（保持不变）
      if (this.showSearchDialog) {
        // ... 弹窗代码保持原样 ...
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#0D1117');
  }
}