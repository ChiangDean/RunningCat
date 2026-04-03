using Godot;

public partial class StartScene : Control
{
	public override void _Ready()
	{
		GetNode<Button>("CenterContainer/StartButton").Pressed += OnStartButtonPressed;
	}

	private void OnStartButtonPressed()
	{
		GetTree().ChangeSceneToFile("res://scenes/HelloWorldScene.tscn");
	}
}
