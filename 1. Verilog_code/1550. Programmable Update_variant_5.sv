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
    
    // Buffer registers for high fanout signal main_reg
    reg [WIDTH-1:0] main_reg_buf1; // Buffer for threshold comparison
    reg [WIDTH-1:0] main_reg_buf2; // Buffer for shadow_data comparison
    reg [WIDTH-1:0] main_reg_buf3; // Buffer for manual update path
    
    // Intermediate signals for update logic
    reg update_manual, update_threshold, update_change, update_periodic;
    reg [WIDTH-1:0] next_shadow_data;
    reg next_updated;
    
    // Main register update
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            main_reg <= 0;
        else
            main_reg <= data_in;
    end
    
    // Buffer registers update - split into separate always blocks
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            main_reg_buf1 <= 0;
        else
            main_reg_buf1 <= main_reg;
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            main_reg_buf2 <= 0;
        else
            main_reg_buf2 <= main_reg;
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            main_reg_buf3 <= 0;
        else
            main_reg_buf3 <= main_reg;
    end
    
    // Update condition detection logic - combinational
    always @(*) begin
        // Default values
        update_manual = 1'b0;
        update_threshold = 1'b0;
        update_change = 1'b0;
        update_periodic = 1'b0;
        
        case (update_mode)
            2'b00: update_manual = manual_trigger;
            2'b01: update_threshold = (main_reg_buf1 > threshold);
            2'b10: update_change = (main_reg_buf2 != shadow_data);
            2'b11: update_periodic = (main_reg != data_in);
        endcase
    end
    
    // Shadow data update value selection - combinational
    always @(*) begin
        next_updated = 1'b0;
        next_shadow_data = shadow_data; // Default: no change
        
        if (update_manual) begin
            next_shadow_data = main_reg_buf3;
            next_updated = 1'b1;
        end
        else if (update_threshold) begin
            next_shadow_data = main_reg_buf1;
            next_updated = 1'b1;
        end
        else if (update_change) begin
            next_shadow_data = main_reg_buf2;
            next_updated = 1'b1;
        end
        else if (update_periodic) begin
            next_shadow_data = main_reg_buf2;
            next_updated = 1'b1;
        end
    end
    
    // Shadow register update - sequential
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shadow_data <= 0;
            updated <= 0;
        end else begin
            shadow_data <= next_shadow_data;
            updated <= next_updated;
        end
    end
endmodule