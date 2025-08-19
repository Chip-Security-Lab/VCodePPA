//SystemVerilog
module multiplier_high_priority (
    input clk,
    input rst_n,
    input [7:0] a,
    input [7:0] b,
    input req,
    output reg ack,
    output reg [15:0] product
);

    reg [15:0] result;
    reg busy;
    wire [15:0] mult_result;
    wire req_rise;
    wire req_fall;

    // Edge detection for req signal
    reg req_d;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) req_d <= 1'b0;
        else req_d <= req;
    end
    assign req_rise = req && !req_d;
    assign req_fall = !req && req_d;

    // Multiplier result calculation
    assign mult_result = a * b;

    // Main state machine
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ack <= 1'b0;
            busy <= 1'b0;
            result <= 16'b0;
        end else begin
            case ({busy, req_rise, req_fall})
                3'b000: begin end
                3'b001: begin end
                3'b010: begin
                    result <= mult_result;
                    busy <= 1'b1;
                    ack <= 1'b1;
                end
                3'b011: begin end
                3'b100: begin end
                3'b101: begin
                    busy <= 1'b0;
                    ack <= 1'b0;
                end
                3'b110: begin end
                3'b111: begin end
            endcase
        end
    end

    // Output register stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            product <= 16'b0;
        end else begin
            product <= result;
        end
    end

endmodule