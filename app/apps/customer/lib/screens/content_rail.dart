import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

import '../src/u1_stub.dart'; // u1-stub: delete when U1 lands
import 'more.dart';

const _cardWidth = 168.0;
const _thumbHeight = 88.0;
const _titleLines = 2;

/// Horizontal cards for one content kind (news, tips). Copy and pictures come from the console;
/// [art] is the 3D icon shown when an item has no picture. Nothing renders while the list is empty.
class ContentRail extends StatelessWidget {
  const ContentRail({
    super.key,
    required this.title,
    required this.kind,
    required this.items,
    required this.art,
  });
  final String title;
  final String kind;
  final List<ContentItem> items;
  final String art;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final style = context.text.labelLarge!;
    final line = (style.fontSize ?? 14) * (style.height ?? 1.4);
    // Two title lines at the user's font size, so large text grows the rail instead of clipping.
    final height =
        _thumbHeight +
        Space.sm * 3 +
        MediaQuery.textScalerOf(context).scale(line * _titleLines);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(
          title,
          trailing: TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => ContentListScreen(kind: kind, title: title),
              ),
            ),
            child: Text(context.t.viewAll),
          ),
        ),
        SizedBox(
          height: height,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: Space.sm),
            itemBuilder: (_, i) => _RailCard(item: items[i], art: art),
          ),
        ),
      ],
    );
  }
}

class _RailCard extends StatelessWidget {
  const _RailCard({required this.item, required this.art});
  final ContentItem item;
  final String art;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fallback = ColoredBox(
      color: c.primaryTint,
      child: Center(child: Icon3D(art, size: 56)),
    );
    final url = item.imageUrl;
    return SizedBox(
      width: _cardWidth,
      child: AppCard(
        padding: EdgeInsets.zero,
        level: Level.flat,
        border: c.line,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ContentDetailScreen(item: item),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(Radii.card),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: _thumbHeight,
                // The picture is decoration; the title below carries the meaning.
                child: ExcludeSemantics(
                  child: url == null
                      ? fallback
                      : Image.network(
                          url,
                          fit: BoxFit.cover,
                          cacheWidth: 504,
                          errorBuilder: (_, _, _) => fallback,
                        ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(Space.sm),
                  child: Text(
                    item.title(context.lang),
                    style: context.text.labelLarge,
                    maxLines: _titleLines,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
