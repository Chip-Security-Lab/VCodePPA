//SystemVerilog
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
    
    // Pipeline registers for breaking critical paths
    reg [WIDTH-1:0] threshold_reg;
    reg [WIDTH-1:0] main_reg_d1;
    reg [WIDTH-1:0] shadow_data_d1;
    reg [1:0] update_mode_reg;
    reg manual_trigger_reg;
    
    // Mode-specific update signals
    reg manual_update;
    reg threshold_update;
    reg change_update;
    reg periodic_update;
    reg any_update_d1;
    
    // Register inputs to break timing paths
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            threshold_reg <= {WIDTH{1'b0}};
            main_reg_d1 <= {WIDTH{1'b0}};
            shadow_data_d1 <= {WIDTH{1'b0}};
            update_mode_reg <= 2'b00;
            manual_trigger_reg <= 1'b0;
        end else begin
            threshold_reg <= threshold;
            main_reg_d1 <= main_reg;
            shadow_data_d1 <= shadow_data;
            update_mode_reg <= update_mode;
            manual_trigger_reg <= manual_trigger;
        end
    end
    
    // Main register update
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            main_reg <= {WIDTH{1'b0}};
        else
            main_reg <= data_in;
    end
    
    // Pre-compute update conditions using pipelined signals
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            manual_update <= 1'b0;
            threshold_update <= 1'b0;
            change_update <= 1'b0;
            periodic_update <= 1'b0;
            any_update_d1 <= 1'b0;
        end else begin
            manual_update <= update_mode_reg == 2'b00 && manual_trigger_reg;
            threshold_update <= update_mode_reg == 2'b01 && (main_reg_d1 > threshold_reg);
            change_update <= update_mode_reg == 2'b10 && (main_reg_d1 != shadow_data_d1);
            periodic_update <= update_mode_reg == 2'b11 && (main_reg_d1 != data_in);
            any_update_d1 <= manual_update || threshold_update || change_update || periodic_update;
        end
    end
    
    // Shadow register update with pipelined logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shadow_data <= {WIDTH{1'b0}};
            updated <= 1'b0;
        end else begin
            updated <= any_update_d1;
            
            if (any_update_d1) begin
                shadow_data <= main_reg_d1;
            end
        end
    end
endmodule