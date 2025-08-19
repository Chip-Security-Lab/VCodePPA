//SystemVerilog
module int_ctrl_auto_clear #(parameter DW=16)(
    input wire clk,
    input wire rst_n,
    input wire ack,
    input wire [DW-1:0] int_src,
    input wire valid_in,
    output wire valid_out,
    output wire [DW-1:0] int_status
);

    // Pipeline register - Stage 1
    reg [DW-1:0] int_src_r1;
    reg [DW-1:0] int_status_r1;
    reg ack_r1;
    reg valid_r1;
    
    // Pipeline register - Stage 2
    reg [DW-1:0] int_src_r2;
    reg [DW-1:0] int_status_r2;
    reg ack_r2;
    reg valid_r2;
    
    // Pipeline register - Stage 3 (output)
    reg [DW-1:0] int_status_r3;
    reg valid_r3;
    
    // Optimized status calculation logic
    wire [DW-1:0] next_status;
    
    // First pipeline stage: register inputs
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            int_src_r1 <= {DW{1'b0}};
            int_status_r1 <= {DW{1'b0}};
            ack_r1 <= 1'b0;
            valid_r1 <= 1'b0;
        end else begin
            int_src_r1 <= int_src;
            int_status_r1 <= int_status;
            ack_r1 <= ack;
            valid_r1 <= valid_in;
        end
    end
    
    // Second pipeline stage: continue processing
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            int_src_r2 <= {DW{1'b0}};
            int_status_r2 <= {DW{1'b0}};
            ack_r2 <= 1'b0;
            valid_r2 <= 1'b0;
        end else begin
            int_src_r2 <= int_src_r1;
            int_status_r2 <= int_status_r1;
            ack_r2 <= ack_r1;
            valid_r2 <= valid_r1;
        end
    end
    
    // Optimized combinational path using efficient boolean logic
    // Compute the next status using parallel bit operations
    // int_status = (int_status | int_src) & ~(ack ? int_status : 0)
    // Simplified to: status = (status | src) & (ack ? ~status : '1)
    assign next_status = (int_status_r2 | int_src_r2) & (ack_r2 ? ~int_status_r2 : {DW{1'b1}});
    
    // Third pipeline stage: final output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            int_status_r3 <= {DW{1'b0}};
            valid_r3 <= 1'b0;
        end else begin
            int_status_r3 <= next_status;
            valid_r3 <= valid_r2;
        end
    end
    
    // Output assignments
    assign int_status = int_status_r3;
    assign valid_out = valid_r3;

endmodule