//SystemVerilog
module temp_compensated_codec (
    input wire clk,
    input wire rst_n,
    input wire [7:0] r_in, g_in, b_in,
    input wire [7:0] temperature,
    input wire comp_enable,
    output reg [15:0] display_out
);
    // Stage 1: Register the inputs first
    reg [7:0] r_in_reg, g_in_reg, b_in_reg, temperature_reg;
    reg comp_enable_reg;
    
    // Stage 2: Calculate and register temperature compensation factors
    reg [3:0] r_factor_stage2, g_factor_stage2, b_factor_stage2;
    
    // Stage 3: RGB adjustment calculation  
    reg [11:0] r_adj_stage3, g_adj_stage3, b_adj_stage3;
    
    // Temperature factor lookup table logic
    function [3:0] calc_r_factor;
        input [7:0] temp;
        begin
            if (temp > 8'd80)      calc_r_factor = 4'd12;
            else if (temp > 8'd60) calc_r_factor = 4'd13;
            else if (temp > 8'd40) calc_r_factor = 4'd14;
            else                   calc_r_factor = 4'd15;
        end
    endfunction
    
    function [3:0] calc_g_factor;
        input [7:0] temp;
        begin
            if (temp > 8'd80)      calc_g_factor = 4'd14;
            else if (temp > 8'd60) calc_g_factor = 4'd15;
            else if (temp > 8'd40) calc_g_factor = 4'd15;
            else if (temp > 8'd20) calc_g_factor = 4'd14;
            else                   calc_g_factor = 4'd13;
        end
    endfunction
    
    function [3:0] calc_b_factor;
        input [7:0] temp;
        begin
            if (temp > 8'd80)      calc_b_factor = 4'd15;
            else if (temp > 8'd60) calc_b_factor = 4'd14;
            else if (temp > 8'd40) calc_b_factor = 4'd13;
            else if (temp > 8'd20) calc_b_factor = 4'd12;
            else                   calc_b_factor = 4'd11;
        end
    endfunction
    
    // Stage 1: Register the inputs directly with minimal logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            r_in_reg <= 8'd0;
            g_in_reg <= 8'd0;
            b_in_reg <= 8'd0;
            temperature_reg <= 8'd0;
            comp_enable_reg <= 1'b0;
        end
        else begin
            r_in_reg <= r_in;
            g_in_reg <= g_in;
            b_in_reg <= b_in;
            temperature_reg <= temperature;
            comp_enable_reg <= comp_enable;
        end
    end
    
    // Stage 2: Calculate and register temperature factors
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            r_factor_stage2 <= 4'd0;
            g_factor_stage2 <= 4'd0;
            b_factor_stage2 <= 4'd0;
        end
        else begin
            r_factor_stage2 <= calc_r_factor(temperature_reg);
            g_factor_stage2 <= calc_g_factor(temperature_reg);
            b_factor_stage2 <= calc_b_factor(temperature_reg);
        end
    end
    
    // Stage 3: Compute adjusted RGB values
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            r_adj_stage3 <= 12'd0;
            g_adj_stage3 <= 12'd0;
            b_adj_stage3 <= 12'd0;
        end
        else begin
            r_adj_stage3 <= comp_enable_reg ? (r_in_reg * r_factor_stage2) : {r_in_reg, 4'b0000};
            g_adj_stage3 <= comp_enable_reg ? (g_in_reg * g_factor_stage2) : {g_in_reg, 4'b0000};
            b_adj_stage3 <= comp_enable_reg ? (b_in_reg * b_factor_stage2) : {b_in_reg, 4'b0000};
        end
    end
    
    // Stage 4: RGB565 format conversion
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            display_out <= 16'h0000;
        else
            display_out <= {r_adj_stage3[11:7], g_adj_stage3[11:6], b_adj_stage3[11:7]};
    end
    
endmodule