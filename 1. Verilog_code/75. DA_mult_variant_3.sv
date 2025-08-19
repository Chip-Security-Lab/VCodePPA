//SystemVerilog
module DA_mult (
    input clk,
    input rst_n,
    input [3:0] x,
    input [3:0] y,
    input req,
    output reg ack,
    output reg [7:0] out
);

    // Internal signals
    reg [3:0] x_reg;
    reg [3:0] y_reg;
    reg req_reg;
    
    // Distributed Arithmetic implementation for 4x4 bit multiplication
    wire [3:0] pp0, pp1, pp2, pp3;
    
    // Generate partial products based on each bit of y_reg
    assign pp0 = y_reg[0] ? x_reg : 4'b0000;
    assign pp1 = y_reg[1] ? x_reg : 4'b0000;
    assign pp2 = y_reg[2] ? x_reg : 4'b0000;
    assign pp3 = y_reg[3] ? x_reg : 4'b0000;
    
    // Shift and add partial products to get final result
    wire [7:0] shifted_pp1 = {pp1, 1'b0};         // pp1 << 1
    wire [7:0] shifted_pp2 = {pp2, 2'b00};        // pp2 << 2
    wire [7:0] shifted_pp3 = {pp3, 3'b000};       // pp3 << 3
    
    // Final summation
    wire [7:0] result = {4'b0000, pp0} + shifted_pp1 + shifted_pp2 + shifted_pp3;
    
    // Register for the result
    reg [7:0] result_reg;

    // Request-Acknowledge handshake logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            x_reg <= 4'b0;
            y_reg <= 4'b0;
            result_reg <= 8'b0;
            req_reg <= 1'b0;
            ack <= 1'b0;
            out <= 8'b0;
        end else begin
            req_reg <= req;
            
            if (req && !req_reg) begin
                // Capture inputs on rising edge of req
                x_reg <= x;
                y_reg <= y;
                result_reg <= result;
                ack <= 1'b1;
                out <= result;
            end else if (!req && req_reg) begin
                // Clear ack on falling edge of req
                ack <= 1'b0;
            end
        end
    end

endmodule