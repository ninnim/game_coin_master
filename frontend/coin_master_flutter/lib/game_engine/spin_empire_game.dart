import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'components/slot_machine_component.dart';
import 'components/village_background_component.dart';

class SpinEmpireGame extends FlameGame {
  late SlotMachineComponent slotMachine;
  late VillageBackgroundComponent villageBackground;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Add village background
    villageBackground = VillageBackgroundComponent(skyColor: '#1565C0');
    add(villageBackground);

    // Add slot machine
    slotMachine = SlotMachineComponent(
      position: Vector2(size.x / 2, size.y * 0.6),
    );
    add(slotMachine);
  }

  void triggerSpin(List<String> results) {
    slotMachine.spin(results);
  }
}
