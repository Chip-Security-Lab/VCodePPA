//SystemVerilog
module counter_array #(parameter NUM=4, WIDTH=4) (
    input wire clk, 
    input wire rst,
    output wire [NUM*WIDTH-1:0] cnts
);
    reg [NUM-1:0] valid_pipeline_reg;
    
    // Optimized pipeline control initialization using non-blocking assignment
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            valid_pipeline_reg <= {NUM{1'b0}};
        end else begin
            valid_pipeline_reg <= {valid_pipeline_reg[NUM-2:0], 1'b1};
        end
    end
    
    genvar i;
    generate
        for(i=0; i<NUM; i=i+1) begin : cnt_inst
            counter_sync_inc_optimized #(
                .WIDTH(WIDTH),
                .STAGE_ID(i)
            ) u_cnt(
                .clk(clk),
                .rst_n(~rst),
                .en(valid_pipeline_reg[i]),
                .cnt(cnts[i*WIDTH +: WIDTH])
            );
        end
    endgenerate
endmodule

module counter_sync_inc_optimized #(
    parameter WIDTH=4,
    parameter STAGE_ID=0
) (
    input wire clk, 
    input wire rst_n, 
    input wire en,
    output reg [WIDTH-1:0] cnt
);
    // Optimized pipeline structure with reduced register stages
    reg [WIDTH-1:0] cnt_next;
    
    // Combined calculation stage
    always @(*) begin
        cnt_next = cnt + 1'b1;
    end
    
    // Single register stage with enable control
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt <= STAGE_ID[WIDTH-1:0]; // Properly sized initialization value
        end else if (en) begin
            cnt <= cnt_next;
        end
    end
endmodule