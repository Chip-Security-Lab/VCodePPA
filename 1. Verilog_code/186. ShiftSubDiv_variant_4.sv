//SystemVerilog
module ShiftSubDiv(
    input clk,
    input rst_n,
    input valid,
    output reg ready,
    input [7:0] dividend,
    input [7:0] divisor,
    output reg [7:0] quotient,
    output reg [7:0] remainder
);
    reg [15:0] rem;
    reg [2:0] state;
    reg [2:0] count;
    
    localparam IDLE = 3'b000;
    localparam CALC = 3'b001;
    localparam DONE = 3'b010;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            ready <= 1'b1;
            quotient <= 8'b0;
            remainder <= 8'b0;
            rem <= 16'b0;
            count <= 3'b0;
        end else begin
            case (state)
                IDLE: begin
                    if (valid && ready) begin
                        state <= CALC;
                        ready <= 1'b0;
                        rem <= {8'b0, dividend};
                        quotient <= 8'b0;
                        count <= 3'b0;
                    end
                end
                
                CALC: begin
                    if (count < 8) begin
                        rem <= rem << 1;
                        if (rem[15:8] >= divisor && divisor != 0) begin
                            rem[15:8] <= rem[15:8] - divisor;
                            quotient[7-count] <= 1'b1;
                        end
                        count <= count + 1;
                    end else begin
                        state <= DONE;
                        remainder <= rem[15:8];
                    end
                end
                
                DONE: begin
                    state <= IDLE;
                    ready <= 1'b1;
                end
            endcase
        end
    end
endmodule