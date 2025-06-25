import typer
from core.openrouter_api import query_model
from models.data_structures import SessionClass

app = typer.Typer()

@app.command()
def chat(prompt: str):
    """
    Send a chat prompt to the model and print the response.
    """
    session = SessionClass.get_current_session()
    response = query_model(prompt, session=session)
    
    if response:
        typer.echo(f"\nResponse: {response}")
        
        # Display session statistics
        typer.echo(f"\n--- Session Stats ---")
        typer.echo(f"Session ID: {session.session_id}")
        typer.echo(f"Session alive time: {session.session_alive_time}")
        typer.echo(f"Total tokens used: {session.total_tokens}")
        typer.echo(f"Total cost: ${session.total_cost:.4f}")
        typer.echo(f"Total entries: {len(session.entries)}")
        if session.models_used:
            typer.echo(f"Models used: {', '.join(session.models_used)}")
    else:
        typer.echo("No response received.")

@app.command()
def session_status():
    """
    Display the current session status.
    """
    session = SessionClass.get_current_session()
    typer.echo(f"Session ID: {session.session_id}")
    typer.echo(f"Session alive time: {session.session_alive_time}")
    typer.echo(f"Total tokens used: {session.total_tokens}")
    typer.echo(f"Total entries: {len(session.entries)}")
    typer.echo(f"Total cost: ${session.total_cost:.4f}")
    if session.models_used:
        typer.echo(f"Models used: {', '.join(session.models_used)}")

if __name__ == "__main__":
    app()