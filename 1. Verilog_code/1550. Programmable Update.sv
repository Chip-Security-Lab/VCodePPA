module programmable_shadow_reg #(
    parameter WIDTH = 16
)(
    input wire clk,
    input wire rst_n,
    input wire [WIDTH-1:0] data_in,
    input wire [1:0] update_mode,
    input wire manual_trigger,
    input wire [WIDTH-1:0] threshold,
    output reg [WIDTH-1:0] shadow_data,
    output reg updated
);
    // Main data register
    reg [WIDTH-1:0] main_reg;
    
    // Main register update
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            main_reg <= 0;
        else
            main_reg <= data_in;
    end
    
    // Programmable shadow update logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shadow_data <= 0;
            updated <= 0;
        end else begin
            updated <= 0;
            
            case (update_mode)
                2'b00: begin // Manual update
                    if (manual_trigger) begin
                        shadow_data <= main_reg;
                        updated <= 1;
                    end
                end
                
                2'b01: begin // Threshold-based update
                    if (main_reg > threshold) begin
                        shadow_data <= main_reg;
                        updated <= 1;
                    end
                end
                
                2'b10: begin // Change-based update
                    if (main_reg != shadow_data) begin
                        shadow_data <= main_reg;
                        updated <= 1;
                    end
                end
                
                2'b11: begin // Periodic update
                    if (main_reg != data_in) begin
                        shadow_data <= main_reg;
                        updated <= 1;
                    end
                end
            endcase
        end
    end
endmodule