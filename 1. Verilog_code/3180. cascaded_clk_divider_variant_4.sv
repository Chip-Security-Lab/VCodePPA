//SystemVerilog
module cascaded_clk_divider(
    input clk_in,
    input rst,
    output [3:0] clk_out
);
    reg [3:0] counter;
    reg [3:0] divider;
    reg [3:0] dividend;
    reg [3:0] divisor;
    reg [3:0] quotient;
    reg [3:0] remainder;
    reg [2:0] bit_index;
    reg division_active;
    
    localparam IDLE = 2'b00;
    localparam DIVIDE = 2'b01;
    localparam DONE = 2'b10;
    reg [1:0] state;
    
    always @(posedge clk_in or posedge rst) begin
        if (rst) begin
            counter <= 4'b0000;
            divider <= 4'b0000;
            dividend <= 4'b0000;
            divisor <= 4'b0100;
            quotient <= 4'b0000;
            remainder <= 4'b0000;
            bit_index <= 3'd3;
            division_active <= 1'b0;
            state <= IDLE;
        end else begin
            counter <= counter + 1'b1;
            
            // Flattened state machine logic
            if (state == IDLE && counter == 4'hF) begin
                dividend <= counter;
                remainder <= 4'b0000;
                quotient <= 4'b0000;
                bit_index <= 3'd3;
                division_active <= 1'b1;
                state <= DIVIDE;
            end else if (state == DIVIDE && division_active) begin
                remainder <= {remainder[2:0], dividend[bit_index]};
                
                if ({remainder[2:0], dividend[bit_index]} >= divisor) begin
                    remainder <= {remainder[2:0], dividend[bit_index]} - divisor;
                    quotient[bit_index] <= 1'b1;
                end
                
                if (bit_index == 3'd0) begin
                    division_active <= 1'b0;
                    state <= DONE;
                end else begin
                    bit_index <= bit_index - 1'b1;
                end
            end else if (state == DONE) begin
                divider <= quotient;
                state <= IDLE;
            end else begin
                state <= IDLE;
            end
            
            // Clock division logic
            divider[0] <= ~divider[0];
            
            if (counter[1:0] == 2'b11)
                divider[1] <= ~divider[1];
                
            if (counter[3:0] == 4'b1111)
                divider[2] <= ~divider[2];
                
            if (counter[3:0] == 4'b1111 && quotient[1])
                divider[3] <= ~divider[3];
        end
    end
    
    assign clk_out = divider;
endmodule