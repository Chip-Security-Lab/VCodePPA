//SystemVerilog
module one_hot_load_reg(
    input clk, rst_n,
    input [23:0] data_word,
    input [2:0] load_select,  // One-hot encoded
    output reg [23:0] data_out
);
    // Registered input signals
    reg [23:0] data_word_reg;
    reg [2:0] load_select_reg;
    
    // Register data_word input signal
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_word_reg <= 24'h0;
        end
        else begin
            data_word_reg <= data_word;
        end
    end
    
    // Register load_select input signal
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            load_select_reg <= 3'b000;
        end
        else begin
            load_select_reg <= load_select;
        end
    end
    
    // Process lower byte (bits 7:0)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            data_out[7:0] <= 8'h0;
        else if (load_select_reg[0])
            data_out[7:0] <= data_word_reg[7:0];
    end
    
    // Process middle byte (bits 15:8)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            data_out[15:8] <= 8'h0;
        else if (load_select_reg[1])
            data_out[15:8] <= data_word_reg[15:8];
    end
    
    // Process upper byte (bits 23:16)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            data_out[23:16] <= 8'h0;
        else if (load_select_reg[2])
            data_out[23:16] <= data_word_reg[23:16];
    end
endmodule