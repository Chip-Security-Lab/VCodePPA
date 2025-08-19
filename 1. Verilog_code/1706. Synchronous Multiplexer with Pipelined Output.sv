module pipeline_mux(
    input clk, resetn,
    input [15:0] in1, in2, in3, in4,
    input [1:0] sel,
    output reg [15:0] pipe_out
);
    reg [15:0] stage1;
    
    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            stage1 <= 16'h0;
            pipe_out <= 16'h0;
        end else begin
            case (sel)
                2'b00: stage1 <= in1;
                2'b01: stage1 <= in2;
                2'b10: stage1 <= in3;
                2'b11: stage1 <= in4;
            endcase
            pipe_out <= stage1;
        end
    end
endmodule