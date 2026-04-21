import router from '@ohos.router';
import webview from '@ohos.web.webview';

interface WebPageParams {
  url: string;
  title: string;
}

@Entry
@Component
struct WebViewPage {
  private webController: webview.WebviewController = new webview.WebviewController();
  private params: WebPageParams = router.getParams() as WebPageParams;
  private url: string = this.params?.url || 'https://www.baidu.com';
  private title: string = this.params?.title || '网页';

  build() {
    Column() {
      Row() {
        Button('← 返回')
          .fontSize(16)
          .backgroundColor('#007DFF')
          .fontColor(Color.White)
          .height(40)
          .padding({ left: 16, right: 16 })
          .borderRadius(20)
          .onClick(() => {
            router.back();
          })
        Text(this.title)
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
        Row().width(60).height(1)
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#FFFFFF')
      .border({ width: { bottom: 1 }, color: '#EEEEEE' })

      Web({ src: this.url, controller: this.webController })
        .width('100%')
        .layoutWeight(1)
        .domStorageAccess(true)
        .fileAccess(true)
        .javaScriptAccess(true)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }
}