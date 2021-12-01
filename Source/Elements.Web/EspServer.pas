﻿namespace RemObjects.Elements.Web;

uses
  RemObjects.InternetPack.Http,
  RemObjects.Elements.Web;

type
  WebServer = public class
  public

    method Start;
    begin
      fServer := new HttpServer();
      fServer.Port := 8000;
      fServer.KeepAlive := true;
      fServer.CloseConnectionsOnShutdown := true;

      fServer.HttpRequest += (sender, e) -> begin
        var lPage := PageFactory:FindClassForPath(e.Request.Path);
        if assigned(lPage) then begin
          var lUrl := Url.UrlWithComponents("http", "lcoalhost", 8000, e.Request.Path, nil, nil, nil);
          Log($"{e.Request.Path} served via {lPage}");
          lPage.Context := new WebContext(new RemObjects.Elements.Web.WebRequest(e.Request, lPage, lUrl), new WebResponse(e.Response));
          lPage.RenderControl(nil);
          e.Response.ContentStream.Seek(0, SeekOrigin.Begin);
        end
        else begin
          var lRedirect := PageFactory:FindRedirectForPath(e.Request.Path);
          if assigned(lRedirect) then begin
            Log($"{e.Request.Path} redirect to {lRedirect}");
            e.Response.HttpCode := System.Net.HttpStatusCode.MovedPermanently;
            e.Response.Header.SetHeaderValue("Location", lRedirect);
            e.Response.ContentString := $"<head><title>Document Moved</title></head><body><h1>Object Moved</h1>This document may be found <a HREF=""{lRedirect}"">here</a></body>";
          end
          else begin
            var lResourceName := PageFactory:FindResourcesForPath(e.Request.Path);
            if assigned(lResourceName) then begin
              //var lResourcePath := new System.Uri('pack://application:,,,/MyImage.png');
              //var lBitmap := new BitmapImage(lResourcePath);
              Log($"{e.Request.Path} serves as resource {lResourceName}");
            end
            else begin
              Log($"{e.Request.Path} 404");
              if not RunError(e, 404) then begin
                e.Response.HttpCode := System.Net.HttpStatusCode.NotFound;
                e.Response.ContentString := $"<h1>404 Not found</h1> {e.Request.Path}";
              end;
            end;
          end;
        end;
      end;

      fServer.Open();
    end;

    method RunError(e: HttpRequestEventArgs; aCode: Integer): Boolean;
    begin
      var lPath := ErrorPaths[aCode];
      if assigned(lPath) then begin
        var lUrl := Url.UrlWithComponents("http", "lcoalhost", 8000, lPath, nil, nil, nil);
        var lPage := PageFactory:FindClassForPath(e.Request.Path);
        if assigned(lPage) then begin
          Log($"{e.Request.Path} error {aCode} served via {lPage}");
          lPage.Context := new WebContext(new RemObjects.Elements.Web.WebRequest(e.Request, lPage, lUrl), new WebResponse(e.Response));
          lPage.RenderControl(nil);
          e.Response.ContentStream.Seek(0, SeekOrigin.Begin);
          exit true;
        end;
      end;
    end;

    method Stop;
    begin
      fServer.Close();
    end;

    property PageFactory: WebPageFactory;
    property ErrorPaths := new Dictionary<Integer,String>;

  private

    fServer: HttpServer;

  end;

  WebServerForContext = public class
  public

    method Transfer(aPath: String);
    begin

    end;

    method HtmlEncode(aString: nullable String): nullable String;
    begin
      {$WARNING Not implemented}
    end;

    method HtmlDecode(aString: nullable String): nullable String;
    begin
      {$WARNING Not implemented}
    end;

  assembly

    constructor(aWebServer: WebServer);
    begin

    end;

  end;

  WebPageFactory = public abstract class
  public
    method FindClassForPath(aPath: not nullable String): nullable Page; abstract;
    method FindRedirectForPath(aPath: not nullable String): nullable String; abstract;
    method FindResourcesForPath(aPath: not nullable String): nullable String; abstract;
  end;

end.