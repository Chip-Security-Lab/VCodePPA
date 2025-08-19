//SystemVerilog
module TimerSync #(parameter WIDTH=16) (
    input clk, rst_n, enable,
    output reg timer_out
);
    reg [WIDTH-1:0] counter;
    reg [WIDTH-1:0] counter_buf1, counter_buf2;
    
    reg [1:0] control;
    
    always @(*) begin
        control = {!rst_n, enable};
    end
    
    always @(posedge clk) begin
        case(control)
            2'b10, 2'b11: begin // !rst_n (reset has priority)
                counter <= 0;
                timer_out <= 0;
            end
            2'b01: begin // enable and not reset
                counter <= (counter == {WIDTH{1'b1}}) ? 0 : counter + 1;
                timer_out <= (counter == {WIDTH{1'b1}});
            end
            2'b00: begin // not enable and not reset
                counter <= counter;
                timer_out <= timer_out;
            end
        endcase
    end
    
    // Fanout buffer registers to reduce loading on counter signal
    always @(posedge clk) begin
        if (!rst_n) begin
            counter_buf1 <= 0;
            counter_buf2 <= 0;
        end else begin
            counter_buf1 <= counter;
            counter_buf2 <= counter;
        end
    end
endmodule