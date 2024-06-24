import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/wish_localizations.dart';
import 'package:get_storage/get_storage.dart';
import 'package:wish/data/style/wish_options.dart';
import 'package:wish/data/wish_data.dart';
import 'package:wish/data/wish_icons.dart';
import 'package:wish/pages/edit_page.dart';
import 'package:wish/pages/list.dart';
import 'package:wish/pages/review_page.dart';
import 'package:wish/pages/setting_page.dart';
import 'package:wish/router/router_utils.dart';
import 'package:wish/themes/wish_theme_data.dart';
import 'package:wish/utils/platform.dart';
import 'package:wish/widgets/drawer.dart';

Future<void> main() async {
  await GetStorage.init();
  if (PlatformUtils.instance.isMobile && Platform.isAndroid) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
      ),
    );
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ModelBinding(
      initialModel: WishOptions(
        themeMode: lastTheme,
        platform: defaultTargetPlatform,
        isTestMode: false,
        locale: lastLocale,
      ),
      child: Builder(builder: (context) {
        final options = WishOptions.of(context);
        return MaterialApp(
          home: const HomePage(),
          themeMode: options.themeMode,
          theme: WishThemeData.lightThemeData.copyWith(
            platform: options.platform,
          ),
          darkTheme: WishThemeData.darkThemeData.copyWith(
            platform: options.platform,
          ),
          locale: options.locale,
          localizationsDelegates: WishLocalizations.localizationsDelegates,
          supportedLocales: WishLocalizations.supportedLocales,
          localeListResolutionCallback: (locales, supportedLocales) {
            print('-----locales: $locales, supportedLocales: $supportedLocales');
            HookData.instance.updateLabelWidth(locales?.first.languageCode);
            return basicLocaleListResolution(locales, supportedLocales);
          },
          // home: Scaffold(
        );
      }),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<StatefulWidget> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late DrawerType _drawerType;
  late SortType _sortType;
  bool _isAsc = false;

  @override
  void initState() {
    super.initState();
    _drawerType = DrawerType.allList;
    _sortType = SortType.createdTime;
  }

  @override
  Widget build(BuildContext context) {
    var localizations = WishLocalizations.of(context)!;
    final String createText;
    switch (_drawerType) {
      case DrawerType.repeatList:
        createText = localizations.menuCreateRepeatTask;
        break;
      case DrawerType.checkInList:
        createText = localizations.menuCreateCheckInTask;
        break;
      case DrawerType.allList:
      case DrawerType.wishList:
      default:
        createText = localizations.menuCreateWish;
        break;
    }
    return Scaffold(

          appBar: AppBar(

          title: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Expanded(
                child: Text(_drawerType.getShowTitle(context)), // Assuming getShowTitle method is defined.
              ),
              Image.network(
                'https://img95.699pic.com/xsj/0s/dr/v1.jpg%21/fh/300', // Replace with your image URL.
                width: 30,
                height: 30,
              ),
            ],
          ),

          actions: [
            PopupMenuButton(itemBuilder: (context) {
              return [
                PopupMenuItem(
                  onTap: () {
                    Future.delayed(Duration.zero, _gotoCreatePage);
                  },
                  child: Text(createText),
                ),
                PopupMenuItem(
                    onTap: () {
                      _showSortDialog(_sortType, _isAsc);
                    },
                    child: Text(localizations.sort)),
              ];
            })
          ],
        ),

        floatingActionButton: FloatingActionButton(
          onPressed: () {
            _gotoCreatePage();
          },
          child: const Icon(
            size: 40,
            Icons.add,
          ),
        ),
        body: WishList(
          drawerType: _drawerType,
          sortType: _sortType,
          isAsc: _isAsc,
          onPressEmpty: _gotoCreatePage,

        ),
        drawer: DrawerLayout(
          drawerType: _drawerType,
          callback: (type) {
            switch (type) {
              case DrawerType.allList:
              case DrawerType.wishList:
              case DrawerType.repeatList:
              case DrawerType.checkInList:
              case DrawerType.doneList:
                setState(() {
                  _drawerType = type;
                });
                break;
              case DrawerType.setting:
                _gotoSettingPage();
                break;
              case DrawerType.review:
                _gotoReviewPage();
                break;
            }
          },
        ));
  }

  _gotoReviewPage() {
    Navigator.push(context, Right2LeftRouter(child: const ReviewPage()));
  }

  _gotoSettingPage() {
    Navigator.push(context, Right2LeftRouter(child: const SettingPage()));
  }

  _gotoCreatePage() {
    Navigator.push(
        context,
        Right2LeftRouter(
            child: EditPage(
          pageType: WishPageType.create,
          wishType: _drawerType.getWishType(),
        )));
  }

  _showSortDialog(SortType sortType, bool isAsc) async {
    buildItem(BuildContext context, SortType itemType) {
      IconData? iconData = itemType == sortType ? (isAsc ? WishIcons.arrowUp : WishIcons.arrowDown) : null;
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          Navigator.pop(context, itemType);
        },
        child: Row(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(itemType.getShowTitle(context), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
            const SizedBox(
              width: 6,
              height: 40,
            ),
            if (iconData != null)
              Icon(
                iconData,
                color: Theme.of(context).colorScheme.primary,
                size: 14,
              ),
          ],
        ),
      );
    }

    final res = await Future.delayed(Duration.zero, () {
      var colorScheme = Theme.of(context).colorScheme;
      var isLight = colorScheme.brightness == Brightness.light;
      return showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (context) {
            return Container(
              margin: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
              padding: const EdgeInsets.only(left: 20, right: 20, bottom: 3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: colorScheme.secondary,
                border: isLight ? null : Border.all(color: WishThemeData.darkGreenBorderColor, width: 1),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text(
                      WishLocalizations.of(context)!.sortDialogTitle,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
                    ),
                  ),
                  buildItem(context, SortType.name),
                  const Divider(height: 1, thickness: 1),
                  buildItem(context, SortType.createdTime),
                  const Divider(height: 1, thickness: 1),
                  buildItem(context, SortType.modifiedTime),
                ],
              ),
            );
          });
    });
    if (res != null) {
      setState(() {
        if (res == sortType) {
          _isAsc = !isAsc;
        } else {
          _sortType = res;
          _isAsc = false;
        }
      });
    }
  }
}
