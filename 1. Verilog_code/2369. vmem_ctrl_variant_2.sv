//SystemVerilog
// Top module
module vmem_ctrl #(
    parameter AW = 12
)(
    input  wire        clk,
    output wire [AW-1:0] addr,
    output wire        ref_en
);

    // Internal signals for module interconnection
    wire [15:0] refresh_counter;
    // Pre-compute refresh trigger condition
    wire        refresh_trigger;
    
    // Instantiate counter module with optimized implementation
    refresh_counter_module #(
        .COUNTER_WIDTH(16)
    ) refresh_counter_inst (
        .clk             (clk),
        .refresh_counter (refresh_counter),
        .refresh_trigger (refresh_trigger)  // Direct connection from counter
    );
    
    // Address generator with improved timing
    address_generator #(
        .AW(AW)
    ) address_gen_inst (
        .clk             (clk),
        .refresh_counter (refresh_counter),
        .refresh_trigger (refresh_trigger),
        .addr            (addr)
    );
    
    // Connect refresh enable output
    assign ref_en = refresh_trigger;
    
endmodule

// Counter module with integrated refresh trigger logic
module refresh_counter_module #(
    parameter COUNTER_WIDTH = 16
)(
    input  wire                    clk,
    output reg  [COUNTER_WIDTH-1:0] refresh_counter,
    output wire                    refresh_trigger
);

    // Pre-compute next counter value to reduce critical path
    wire [COUNTER_WIDTH-1:0] next_counter;
    assign next_counter = refresh_counter + 1'b1;
    
    // Pre-compute refresh trigger from next counter to balance paths
    assign refresh_trigger = (next_counter[15:13] == 3'b111);
    
    // Counter logic
    always @(posedge clk) begin
        refresh_counter <= next_counter;
    end
    
endmodule

// Module to generate memory addresses with improved timing
module address_generator #(
    parameter AW = 12
)(
    input  wire        clk,
    input  wire [15:0] refresh_counter,
    input  wire        refresh_trigger,
    output reg  [AW-1:0] addr
);

    // Pre-compute next address for faster path
    wire [AW-1:0] next_addr;
    assign next_addr = refresh_counter[AW-1:0];
    
    // Split complex condition for better timing
    reg refresh_active;
    
    always @(posedge clk) begin
        refresh_active <= refresh_trigger;
    end
    
    // Address update logic with reduced critical path
    always @(posedge clk) begin
        if (refresh_active) begin
            addr <= next_addr;
        end
    end
    
endmodule