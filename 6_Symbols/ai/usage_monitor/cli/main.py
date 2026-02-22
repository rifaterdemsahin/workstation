import typer
import time
from core.openrouter_api import query_model
from models.data_structures import SessionClass
from rich.console import Console
from rich.panel import Panel
from rich.progress import Progress, SpinnerColumn, TextColumn
from rich.table import Table
from rich.text import Text
from rich.align import Align

console = Console()
app = typer.Typer()

def display_beautiful_stats(session: SessionClass):
    """Display session stats with animations and emojis"""
    
    # Create a spinner animation
    with Progress(
        SpinnerColumn(),
        TextColumn("[bold blue]Calculating session stats..."),
        console=console,
        transient=True,
    ) as progress:
        task = progress.add_task("stats", total=None)
        time.sleep(1.5)  # Simulate calculation time
    
    # Create a beautiful stats table
    stats_table = Table(show_header=False, show_edge=False, pad_edge=False)
    stats_table.add_column("Metric", style="bold cyan", width=20)
    stats_table.add_column("Value", style="bold green")
    
    # Add rows with emojis
    stats_table.add_row("🆔 Session ID", f"[yellow]{session.session_id}[/yellow]")
    stats_table.add_row("⏰ Alive Time", f"[magenta]{session.session_alive_time}[/magenta]")
    stats_table.add_row("🔢 Total Tokens", f"[blue]{session.total_tokens:,}[/blue]")
    stats_table.add_row("💰 Total Cost", f"[red]${session.total_cost:.4f}[/red]")
    stats_table.add_row("📊 Total Entries", f"[green]{len(session.entries)}[/green]")
    
    if session.models_used:
        models_text = ", ".join(session.models_used)
        stats_table.add_row("🤖 Models Used", f"[purple]{models_text}[/purple]")
    
    # Create the main panel
    panel = Panel(
        Align.center(stats_table),
        title="[bold blue]✨ Session Statistics ✨[/bold blue]",
        title_align="center",
        border_style="bright_blue",
        padding=(1, 2)
    )
    
    console.print()
    console.print(panel)
    console.print()

@app.command()
def chat(prompt: str):
    """
    Send a chat prompt to the model and print the response.
    """
    session = SessionClass.get_current_session()
    response = query_model(prompt, session=session)
    
    if response:
        # Display response in a beautiful panel
        response_panel = Panel(
            response,
            title="[bold green]🤖 AI Response[/bold green]",
            title_align="center",
            border_style="green",
            padding=(1, 2)
        )
        console.print()
        console.print(response_panel)
        
        # Display beautiful session statistics
        display_beautiful_stats(session)
    else:
        console.print("[bold red]❌ No response received.[/bold red]")

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

@app.command()
def stats():
    """
    Display beautiful animated session statistics with emojis.
    """
    session = SessionClass.get_current_session()
    display_beautiful_stats(session)

if __name__ == "__main__":
    app()