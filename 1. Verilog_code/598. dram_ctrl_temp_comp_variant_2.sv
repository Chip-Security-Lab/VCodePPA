//SystemVerilog
module dram_ctrl_temp_comp #(
    parameter BASE_REFRESH = 7800
)(
    input clk,
    input [7:0] temperature,
    output reg refresh_req
);

    reg [15:0] refresh_counter;
    wire [15:0] refresh_interval;
    
    // Optimized temperature scaling using shift and add
    wire [15:0] temp_scaled = ({8'b0, temperature} << 3) + ({8'b0, temperature} << 1); // temperature * 10
    
    // Optimized refresh interval calculation using direct addition
    assign refresh_interval = BASE_REFRESH + temp_scaled;
    
    // Optimized comparison logic using a single comparator
    wire counter_ge_interval = (refresh_counter >= refresh_interval);
    
    always @(posedge clk) begin
        if(counter_ge_interval) begin
            refresh_req <= 1'b1;
            refresh_counter <= 16'd0;
        end else begin
            refresh_req <= 1'b0;
            refresh_counter <= refresh_counter + 16'd1;
        end
    end
endmodule