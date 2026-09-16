import 'package:flutter/material.dart';

import '../../models/google_route.dart';
import '../../models/route_request.dart';
import '../../services/route_service.dart';
import '../../widgets/route_option_card.dart';

class PlanResultsScreen extends StatefulWidget {
  const PlanResultsScreen({
    super.key,
  });

  @override
  State<PlanResultsScreen> createState() => _PlanResultsScreenState();
}

class _PlanResultsScreenState extends State<PlanResultsScreen> {
  late Future<List<GoogleRoute>> _routesFuture;

  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_loaded) {
      return;
    }

    final request =
        ModalRoute.of(context)!.settings.arguments as RouteRequest;

    _routesFuture = RouteService.getRoutes(request);

    _loaded = true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Route Options'),
      ),
      body: FutureBuilder<List<GoogleRoute>>(
        future: _routesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Unable to find routes.\n\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final routes = snapshot.data ?? [];

          if (routes.isEmpty) {
            return const Center(
              child: Text(
                'No transit routes found.',
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: routes.length,
            itemBuilder: (context, index) {
              final route = routes[index];

              return RouteOptionCard(
                route: route,
                onTap: () {
                  // We will connect the route detail screen next.
                },
              );
            },
          );
        },
      ),
    );
  }
}