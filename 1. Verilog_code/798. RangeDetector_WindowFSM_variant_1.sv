//SystemVerilog
// Window Comparator Module
module WindowComparator #(
    parameter WIDTH = 8
)(
    input [WIDTH-1:0] data_in,
    input [WIDTH-1:0] win_low,
    input [WIDTH-1:0] win_high,
    output below_window,
    output above_window,
    output inside_window
);
    // Comparison logic
    assign below_window = (data_in < win_low);
    assign above_window = (data_in > win_high);
    assign inside_window = ~(below_window || above_window);
endmodule

// State Machine Module
module WindowFSM (
    input clk, 
    input rst_n,
    input below_window,
    input above_window,
    input inside_window,
    output reg cross_event
);
    // FSM state definitions
    localparam INSIDE = 1'b0;
    localparam OUTSIDE = 1'b1;

    // State registers
    reg current_state;
    reg next_state;
    
    // State transition detection
    wire state_transition;
    
    // Next state logic
    always @(*) begin
        case(current_state)
            INSIDE:  next_state = (below_window || above_window) ? OUTSIDE : INSIDE;
            OUTSIDE: next_state = inside_window ? INSIDE : OUTSIDE;
            default: next_state = INSIDE;
        endcase
    end
    
    // State register update - synchronous reset
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) 
            current_state <= INSIDE;
        else 
            current_state <= next_state;
    end
    
    // State transition detection
    assign state_transition = (current_state != next_state);
    
    // Event output register - triggered only on state transition
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)
            cross_event <= 1'b0;
        else
            cross_event <= state_transition;
    end
endmodule

// Top-level module
module RangeDetector_WindowFSM #(
    parameter WIDTH = 8
)(
    input clk, 
    input rst_n,
    input [WIDTH-1:0] data_in,
    input [WIDTH-1:0] win_low,
    input [WIDTH-1:0] win_high,
    output cross_event
);
    // Internal signals
    wire below_window;
    wire above_window;
    wire inside_window;
    
    // Instantiate Window Comparator
    WindowComparator #(
        .WIDTH(WIDTH)
    ) window_comp (
        .data_in(data_in),
        .win_low(win_low),
        .win_high(win_high),
        .below_window(below_window),
        .above_window(above_window),
        .inside_window(inside_window)
    );
    
    // Instantiate Window FSM
    WindowFSM window_fsm (
        .clk(clk),
        .rst_n(rst_n),
        .below_window(below_window),
        .above_window(above_window),
        .inside_window(inside_window),
        .cross_event(cross_event)
    );
    
endmodule