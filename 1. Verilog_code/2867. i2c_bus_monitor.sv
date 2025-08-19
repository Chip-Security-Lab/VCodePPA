module i2c_bus_monitor(
    input wire clk, rst_n,
    input wire enable_monitor,
    output reg bus_busy,
    output reg [7:0] last_addr, last_data,
    output reg error_detected,
    inout wire sda, scl
);
    reg sda_prev, scl_prev;
    reg [2:0] monitor_state;
    reg [7:0] shift_reg;
    reg [3:0] bit_count;
    
    wire start_cond = scl && sda_prev && !sda;
    wire stop_cond = scl && !sda_prev && sda;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            monitor_state <= 3'b000;
            bus_busy <= 1'b0;
        end else if (enable_monitor) begin
            if (start_cond) begin
                bus_busy <= 1'b1;
                monitor_state <= 3'b001;
            end else if (stop_cond) begin
                bus_busy <= 1'b0;
                monitor_state <= 3'b000;
            end
        end
    end
endmodule