//SystemVerilog
module sawtooth_generator(
    input clock,
    input areset,
    input en,
    output reg [7:0] sawtooth
);
    reg [1:0] state;
    
    always @(posedge clock or posedge areset) begin
        if (areset) begin
            sawtooth <= 8'h00;
            state <= 2'b00;
        end else if (state == 2'b00 && en) begin
            sawtooth <= sawtooth + 8'h01;
            state <= 2'b01;
        end else if (state == 2'b01 && en) begin
            sawtooth <= sawtooth + 8'h01;
        end else if (state == 2'b01 && !en) begin
            state <= 2'b00;
        end else if (state != 2'b00 && state != 2'b01) begin
            state <= 2'b00;
        end
    end
endmodule