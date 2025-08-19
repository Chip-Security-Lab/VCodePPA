//SystemVerilog
// Top-level module
module sync_rst_div #(
    parameter DIV = 8
) (
    input  wire clk,
    input  wire async_rst,
    output wire clk_out
);

    // Internal connections
    wire sync_rst;
    
    // Instantiate reset synchronizer
    reset_synchronizer rst_sync_inst (
        .clk        (clk),
        .async_rst  (async_rst),
        .sync_rst   (sync_rst)
    );
    
    // Instantiate clock divider
    clock_divider_optimized #(
        .DIV        (DIV)
    ) clk_div_inst (
        .clk        (clk),
        .sync_rst   (sync_rst),
        .clk_out    (clk_out)
    );
    
endmodule

// Reset synchronizer module with enhanced pipeline
module reset_synchronizer (
    input  wire clk,
    input  wire async_rst,
    output wire sync_rst
);
    
    // Two-stage synchronizer is typically sufficient
    // Using shift register structure for better synthesis
    (* async_reg = "true" *) reg [1:0] sync_rst_meta;
    reg sync_rst_out;
    
    always @(posedge clk or posedge async_rst) begin
        if (async_rst) begin
            sync_rst_meta <= 2'b11;
            sync_rst_out <= 1'b1;
        end
        else begin
            sync_rst_meta <= {sync_rst_meta[0], 1'b0};
            sync_rst_out <= sync_rst_meta[1];
        end
    end
    
    assign sync_rst = sync_rst_out;
    
endmodule

// Optimized clock divider module
module clock_divider_optimized #(
    parameter DIV = 8
) (
    input  wire clk,
    input  wire sync_rst,
    output reg  clk_out
);
    
    // Optimize counter bit width
    localparam CNT_WIDTH = $clog2(DIV/2);
    localparam TERMINAL_COUNT = (DIV/2-1);
    
    // Simplified counter and control logic
    reg [CNT_WIDTH-1:0] counter;
    wire terminal_count_reached;
    
    // Efficient comparison with terminal count
    assign terminal_count_reached = (counter == TERMINAL_COUNT);
    
    // Counter logic
    always @(posedge clk) begin
        if (sync_rst) begin
            counter <= {CNT_WIDTH{1'b0}};
        end
        else if (terminal_count_reached) begin
            counter <= {CNT_WIDTH{1'b0}};
        end
        else begin
            counter <= counter + 1'b1;
        end
    end
    
    // Output clock toggle logic - reduced latency
    always @(posedge clk) begin
        if (sync_rst) begin
            clk_out <= 1'b0;
        end
        else if (terminal_count_reached) begin
            clk_out <= ~clk_out;
        end
    end
    
endmodule