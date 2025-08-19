//SystemVerilog
module sync_mux_with_reset(
    input clk, rst_n,
    input [31:0] data_a, data_b,
    input req_a, req_b,
    output reg ack_a, ack_b,
    output reg [31:0] result
);

    reg [1:0] state;
    reg [31:0] data_reg;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= 2'b00;
            result <= 32'h0;
            ack_a <= 1'b0;
            ack_b <= 1'b0;
            data_reg <= 32'h0;
        end
        else begin
            case (state)
                2'b00: begin
                    if (req_a) begin
                        state <= 2'b01;
                        data_reg <= data_a;
                        ack_a <= 1'b1;
                        ack_b <= 1'b0;
                    end
                    else if (req_b) begin
                        state <= 2'b10;
                        data_reg <= data_b;
                        ack_a <= 1'b0;
                        ack_b <= 1'b1;
                    end
                    else begin
                        state <= 2'b00;
                        ack_a <= 1'b0;
                        ack_b <= 1'b0;
                    end
                end
                2'b01: begin
                    if (!req_a) begin
                        state <= 2'b00;
                        result <= data_reg;
                        ack_a <= 1'b0;
                    end
                end
                2'b10: begin
                    if (!req_b) begin
                        state <= 2'b00;
                        result <= data_reg;
                        ack_b <= 1'b0;
                    end
                end
                default: begin
                    state <= 2'b00;
                    ack_a <= 1'b0;
                    ack_b <= 1'b0;
                end
            endcase
        end
    end
endmodule