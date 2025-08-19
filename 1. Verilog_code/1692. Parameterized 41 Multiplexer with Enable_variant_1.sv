//SystemVerilog
module param_mux_4to1 #(
    parameter WIDTH = 16
)(
    input clk,
    input rst_n,
    input [WIDTH-1:0] in0, in1, in2, in3,
    input [1:0] select,
    input enable,
    output reg [WIDTH-1:0] dout
);

    // Pipeline stage registers
    reg [WIDTH-1:0] stage0_0_reg, stage0_1_reg;
    reg [WIDTH-1:0] stage1_0_reg;
    reg [WIDTH-1:0] final_out_reg;
    
    // Stage 0: First level selection with registers
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage0_0_reg <= {WIDTH{1'b0}};
            stage0_1_reg <= {WIDTH{1'b0}};
        end else begin
            stage0_0_reg <= select[0] ? in1 : in0;
            stage0_1_reg <= select[0] ? in3 : in2;
        end
    end
    
    // Stage 1: Second level selection with register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_0_reg <= {WIDTH{1'b0}};
        end else begin
            stage1_0_reg <= select[1] ? stage0_1_reg : stage0_0_reg;
        end
    end
    
    // Final stage: Enable control with register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            final_out_reg <= {WIDTH{1'b0}};
        end else begin
            final_out_reg <= enable ? stage1_0_reg : {WIDTH{1'b0}};
        end
    end
    
    // Output assignment
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dout <= {WIDTH{1'b0}};
        end else begin
            dout <= final_out_reg;
        end
    end

endmodule