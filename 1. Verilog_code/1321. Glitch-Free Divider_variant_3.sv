//SystemVerilog
///////////////////////////////////////////////////////////////////////////
// Module: glitch_free_divider
// Description: Top-level module for a glitch-free clock divider
///////////////////////////////////////////////////////////////////////////
module glitch_free_divider #(
    parameter DIVIDE_BY = 4  // Clock division factor (divide by 8)
) (
    input  wire clk_i,       // Input clock
    input  wire rst_i,       // Synchronous reset, active high
    output wire clk_o        // Output clock, glitch-free
);
    // Internal signals
    wire pos_edge_clk;
    
    // Counter and positive edge clock generator
    counter_and_pos_clock #(
        .DIVIDE_BY(DIVIDE_BY)
    ) counter_inst (
        .clk_i      (clk_i),
        .rst_i      (rst_i),
        .pos_edge_clk_o (pos_edge_clk)
    );
    
    // Negative edge synchronizer to prevent glitches
    neg_edge_synchronizer neg_sync_inst (
        .clk_i      (clk_i),
        .rst_i      (rst_i),
        .pos_edge_clk_i (pos_edge_clk),
        .sync_clk_o (clk_o)
    );

endmodule

///////////////////////////////////////////////////////////////////////////
// Module: counter_and_pos_clock
// Description: Counts clock cycles and generates positive edge clock
///////////////////////////////////////////////////////////////////////////
module counter_and_pos_clock #(
    parameter DIVIDE_BY = 4  // Clock division factor
) (
    input  wire clk_i,           // Input clock
    input  wire rst_i,           // Synchronous reset, active high
    output reg  pos_edge_clk_o   // Positive edge generated clock
);
    // Local parameters
    localparam COUNTER_WIDTH = $clog2(DIVIDE_BY);
    localparam HALF_DIVIDE = (DIVIDE_BY / 2) - 1;
    
    // Counter register
    reg [COUNTER_WIDTH-1:0] count_r;
    
    // Counter and positive edge clock generation
    always @(posedge clk_i) begin
        case (rst_i)
            1'b1: begin
                count_r <= {COUNTER_WIDTH{1'b0}};
                pos_edge_clk_o <= 1'b0;
            end
            1'b0: begin
                case (count_r)
                    HALF_DIVIDE: begin
                        count_r <= {COUNTER_WIDTH{1'b0}};
                        pos_edge_clk_o <= ~pos_edge_clk_o;
                    end
                    default: begin
                        count_r <= count_r + 1'b1;
                    end
                endcase
            end
        endcase
    end
    
endmodule

///////////////////////////////////////////////////////////////////////////
// Module: neg_edge_synchronizer
// Description: Synchronizes the clock signal on negative edge to eliminate glitches
///////////////////////////////////////////////////////////////////////////
module neg_edge_synchronizer (
    input  wire clk_i,          // Input clock
    input  wire rst_i,          // Synchronous reset, active high
    input  wire pos_edge_clk_i, // Positive edge generated clock
    output wire sync_clk_o      // Synchronized output clock
);
    // Negative edge synchronizer register
    reg neg_edge_clk_r;
    
    // Negative edge synchronizer logic
    always @(negedge clk_i) begin
        case (rst_i)
            1'b1: neg_edge_clk_r <= 1'b0;
            1'b0: neg_edge_clk_r <= pos_edge_clk_i;
        endcase
    end
    
    // Output assignment
    assign sync_clk_o = neg_edge_clk_r;
    
endmodule