//SystemVerilog
module counter_dual_edge #(parameter WIDTH=4) (
    input clk, rst,
    output reg [WIDTH-1:0] cnt
);
    reg [WIDTH-1:0] pos_cnt;
    reg [WIDTH-1:0] neg_cnt;
    
    // Posedge flip-flops
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pos_cnt <= {WIDTH{1'b0}};
            cnt <= {WIDTH{1'b0}};
        end
        else begin
            pos_cnt <= pos_cnt + 1'b1;
            cnt <= (pos_cnt + 1'b1) + neg_cnt;
        end
    end
    
    // Negedge flip-flops
    always @(negedge clk or posedge rst) begin
        if (rst) begin
            neg_cnt <= {WIDTH{1'b0}};
        end
        else begin
            neg_cnt <= neg_cnt + 1'b1;
        end
    end
endmodule