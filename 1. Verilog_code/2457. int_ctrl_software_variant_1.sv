//SystemVerilog
module int_ctrl_software #(parameter WIDTH=8)(
    input clk, rst_n, wr_en,
    input [WIDTH-1:0] sw_int,
    output [WIDTH-1:0] int_out
);
    // Stage 1: Input registration
    reg [WIDTH-1:0] wr_en_reg_stage1;
    reg [WIDTH-1:0] sw_int_reg_stage1;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_en_reg_stage1 <= {WIDTH{1'b0}};
            sw_int_reg_stage1 <= {WIDTH{1'b0}};
        end else begin
            wr_en_reg_stage1 <= {WIDTH{wr_en}};
            sw_int_reg_stage1 <= sw_int;
        end
    end
    
    // Stage 2: Intermediate stage to break down computation
    reg [WIDTH-1:0] wr_en_reg_stage2;
    reg [WIDTH-1:0] sw_int_reg_stage2;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_en_reg_stage2 <= {WIDTH{1'b0}};
            sw_int_reg_stage2 <= {WIDTH{1'b0}};
        end else begin
            wr_en_reg_stage2 <= wr_en_reg_stage1;
            sw_int_reg_stage2 <= sw_int_reg_stage1;
        end
    end
    
    // Stage 3: Final computation and output registration
    reg [WIDTH-1:0] int_out_reg;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            int_out_reg <= {WIDTH{1'b0}};
        end else begin
            int_out_reg <= wr_en_reg_stage2 & sw_int_reg_stage2;
        end
    end
    
    // Output assignment
    assign int_out = int_out_reg;
endmodule