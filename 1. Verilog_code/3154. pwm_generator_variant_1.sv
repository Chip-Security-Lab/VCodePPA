//SystemVerilog
module pwm_generator_axi_stream (
    input clk,
    input rst_n,
    
    // AXI-Stream Slave Interface
    input [7:0] s_axis_tdata,
    input s_axis_tvalid,
    output reg s_axis_tready,
    
    // PWM Output
    output reg pwm_out
);

    reg [7:0] counter;
    reg [7:0] duty_cycle_reg;
    reg data_valid;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 8'h00;
            pwm_out <= 1'b0;
            duty_cycle_reg <= 8'h00;
            s_axis_tready <= 1'b1;
            data_valid <= 1'b0;
        end else begin
            // AXI-Stream handshake
            if (s_axis_tvalid && s_axis_tready) begin
                duty_cycle_reg <= s_axis_tdata;
                data_valid <= 1'b1;
            end
            
            // PWM generation
            if (data_valid) begin
                counter <= counter + 1'b1;
                if (counter < duty_cycle_reg) begin
                    pwm_out <= 1'b1;
                end else begin
                    pwm_out <= 1'b0;
                end
            end
        end
    end
endmodule