module parity_shadow_reg #(
    parameter WIDTH = 8
)(
    input wire clk,
    input wire rst_n,
    input wire [WIDTH-1:0] data_in,
    input wire update,
    output reg [WIDTH-1:0] shadow_data,
    output reg parity_error
);
    // Working register and its parity
    reg [WIDTH-1:0] work_reg;
    reg work_parity;
    
    // Shadow register and its parity
    reg shadow_parity;
    
    // Update working register and calculate parity
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            work_reg <= 0;
            work_parity <= 0;
        end else if (update) begin
            work_reg <= data_in;
            work_parity <= ^data_in; // Parity calculation
        end
    end
    
    // Update shadow register and detect errors
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shadow_data <= 0;
            shadow_parity <= 0;
            parity_error <= 0;
        end else if (update) begin
            shadow_data <= work_reg;
            shadow_parity <= work_parity;
            parity_error <= (^work_reg) != work_parity;
        end
    end
endmodule