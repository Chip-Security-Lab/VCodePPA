//SystemVerilog
///////////////////////////////////////////////////////////
// Module: sync_low_rst_counter
// File: sync_low_rst_counter.v
// Description: Top-level counter module with low active reset
// Standard: IEEE 1364-2005
///////////////////////////////////////////////////////////
module sync_low_rst_counter #(
    parameter COUNT_WIDTH = 8
)(
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire                  load,
    input  wire [COUNT_WIDTH-1:0] load_value,
    output wire [COUNT_WIDTH-1:0] counter
);

    // Internal signals
    wire                   clear_counter;
    wire                   update_counter;
    wire [COUNT_WIDTH-1:0] next_count_value;

    // Counter control logic submodule
    counter_control #(
        .COUNT_WIDTH(COUNT_WIDTH)
    ) u_counter_control (
        .clk            (clk),
        .rst_n          (rst_n),
        .load           (load),
        .load_value     (load_value),
        .current_count  (counter),
        .clear_counter  (clear_counter),
        .update_counter (update_counter),
        .next_value     (next_count_value)
    );

    // Counter register submodule
    counter_register #(
        .COUNT_WIDTH(COUNT_WIDTH)
    ) u_counter_register (
        .clk            (clk),
        .rst_n          (rst_n),
        .clear_counter  (clear_counter),
        .update_counter (update_counter),
        .next_value     (next_count_value),
        .counter        (counter)
    );

endmodule

///////////////////////////////////////////////////////////
// Module: counter_control
// File: counter_control.v
// Description: Control logic for counter operations
// Standard: IEEE 1364-2005
///////////////////////////////////////////////////////////
module counter_control #(
    parameter COUNT_WIDTH = 8
)(
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire                  load,
    input  wire [COUNT_WIDTH-1:0] load_value,
    input  wire [COUNT_WIDTH-1:0] current_count,
    output reg                    clear_counter,
    output reg                    update_counter,
    output reg  [COUNT_WIDTH-1:0] next_value
);

    // Control logic for reset condition detection
    // Generate clear_counter signal based on reset
    always @(*) begin
        clear_counter = !rst_n;
    end
    
    // Control logic for update condition detection
    // Determine when counter should be updated
    always @(*) begin
        update_counter = rst_n;
    end
    
    // Next value calculation logic
    // Determine the next counter value based on load signal
    always @(*) begin
        if (load)
            next_value = load_value;
        else
            next_value = current_count + 1'b1;
    end

endmodule

///////////////////////////////////////////////////////////
// Module: counter_register
// File: counter_register.v
// Description: Register logic that stores and updates counter value
// Standard: IEEE 1364-2005
///////////////////////////////////////////////////////////
module counter_register #(
    parameter COUNT_WIDTH = 8
)(
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire                  clear_counter,
    input  wire                  update_counter,
    input  wire [COUNT_WIDTH-1:0] next_value,
    output reg  [COUNT_WIDTH-1:0] counter
);

    // Reset logic - handles counter clear operation
    always @(posedge clk) begin
        if (clear_counter)
            counter <= {COUNT_WIDTH{1'b0}};
    end
    
    // Update logic - handles counter value update
    always @(posedge clk) begin
        if (!clear_counter && update_counter)
            counter <= next_value;
    end

endmodule