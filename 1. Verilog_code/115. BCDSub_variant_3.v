module BCDSub(
    input wire clk,
    input wire rst_n,
    input wire [7:0] bcd_a,
    input wire [7:0] bcd_b,
    output reg [7:0] bcd_res
);

    // Pipeline stage 1: Comparison and subtraction
    reg [7:0] sub_result;
    reg borrow_flag;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sub_result <= 8'h0;
            borrow_flag <= 1'b0;
        end else begin
            sub_result <= bcd_a - bcd_b;
            borrow_flag <= (bcd_a < bcd_b);
        end
    end

    // Pipeline stage 2: Final result calculation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bcd_res <= 8'h0;
        end else begin
            if (borrow_flag) begin
                bcd_res <= sub_result - 8'h6;
            end else begin
                bcd_res <= sub_result;
            end
        end
    end

endmodule