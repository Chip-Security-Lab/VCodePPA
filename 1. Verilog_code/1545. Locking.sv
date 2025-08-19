module locking_shadow_reg #(
    parameter WIDTH = 16
)(
    input wire clk,
    input wire rst_n,
    input wire [WIDTH-1:0] data_in,
    input wire lock_req,
    input wire unlock_req,
    input wire capture,
    output reg [WIDTH-1:0] shadow_data,
    output reg locked
);
    // Main register
    reg [WIDTH-1:0] main_reg;
    
    // Main register update
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            main_reg <= 0;
        else
            main_reg <= data_in;
    end
    
    // Lock control logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            locked <= 0;
        else if (lock_req)
            locked <= 1;
        else if (unlock_req)
            locked <= 0;
    end
    
    // Shadow register update with lock protection
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            shadow_data <= 0;
        else if (capture && !locked)
            shadow_data <= main_reg;
    end
endmodule