//SystemVerilog
// Top level module - RingScheduler
module RingScheduler #(
    parameter BUF_SIZE = 8
) (
    input  wire clk,
    input  wire rst_n,
    output wire [BUF_SIZE-1:0] events
);
    // Internal signals for connecting submodules
    wire [2:0] current_ptr;
    wire [2:0] next_ptr;
    wire [BUF_SIZE-1:0] current_events;
    wire [BUF_SIZE-1:0] next_events;
    wire [BUF_SIZE-1:0] next_events_from_gen;
    
    // Pointer control submodule instance
    PointerControl #(
        .BUF_SIZE(BUF_SIZE)
    ) pointer_ctrl_inst (
        .clk(clk),
        .rst_n(rst_n),
        .current_ptr(current_ptr),
        .next_ptr(next_ptr)
    );

    // Event generator submodule instance
    EventGenerator #(
        .BUF_SIZE(BUF_SIZE)
    ) event_gen_inst (
        .clk(clk),
        .rst_n(rst_n),
        .current_ptr(current_ptr),
        .current_events(current_events),
        .next_events(next_events_from_gen)
    );

    // Connect to next_events
    assign next_events = next_events_from_gen;

    // State register submodule instance
    StateRegister #(
        .BUF_SIZE(BUF_SIZE)
    ) state_reg_inst (
        .clk(clk),
        .rst_n(rst_n),
        .next_ptr(next_ptr),
        .next_events(next_events),
        .current_ptr(current_ptr),
        .current_events(current_events)
    );

    // Connect the output
    assign events = current_events;

endmodule

// Pointer Control submodule - handles pointer arithmetic
module PointerControl #(
    parameter BUF_SIZE = 8
) (
    input  wire clk,
    input  wire rst_n,
    input  wire [2:0] current_ptr,
    output reg [2:0] next_ptr
);
    // Calculate next pointer value and register it
    always @(posedge clk) begin
        if (!rst_n) begin
            next_ptr <= 3'b001;  // Reset to 1 as it will become current_ptr=0 after reset
        end else begin
            next_ptr <= current_ptr + 3'b001;
        end
    end

endmodule

// Event Generator submodule - handles event generation logic
module EventGenerator #(
    parameter BUF_SIZE = 8
) (
    input  wire clk,
    input  wire rst_n,
    input  wire [2:0] current_ptr,
    input  wire [BUF_SIZE-1:0] current_events,
    output reg [BUF_SIZE-1:0] next_events
);
    // Generate the next event pattern and register it
    wire [BUF_SIZE-1:0] next_events_comb;
    assign next_events_comb = (current_events << 1) | (current_events[BUF_SIZE-1]);
    
    always @(posedge clk) begin
        if (!rst_n) begin
            next_events <= {{(BUF_SIZE-1){1'b0}}, 1'b1} << 1;  // Adjusted for reset
        end else begin
            next_events <= next_events_comb;
        end
    end

endmodule

// State Register submodule - handles register updates
module StateRegister #(
    parameter BUF_SIZE = 8
) (
    input  wire clk,
    input  wire rst_n,
    input  wire [2:0] next_ptr,
    input  wire [BUF_SIZE-1:0] next_events,
    output reg  [2:0] current_ptr,
    output reg  [BUF_SIZE-1:0] current_events
);
    // Sequential logic to update state
    always @(posedge clk) begin
        if (!rst_n) begin
            current_ptr <= 3'b000;
            current_events <= {{(BUF_SIZE-1){1'b0}}, 1'b1};
        end else begin
            current_ptr <= next_ptr;
            current_events <= next_events;
        end
    end

endmodule