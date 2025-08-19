//SystemVerilog
module counter_mode_cipher #(parameter CTR_WIDTH = 16, DATA_WIDTH = 32) (
    input wire clk, reset,
    input wire enable, encrypt,
    input wire [CTR_WIDTH-1:0] init_ctr,
    input wire [DATA_WIDTH-1:0] data_in, key,
    output reg [DATA_WIDTH-1:0] data_out,
    output reg data_valid
);
    reg [CTR_WIDTH-1:0] counter;
    reg [CTR_WIDTH-1:0] counter_expanded [1:0];
    reg [DATA_WIDTH-1:0] key_reg;
    reg [DATA_WIDTH-1:0] encrypted_ctr;
    reg [DATA_WIDTH-1:0] data_in_reg;
    reg enable_pipe;
    
    // Counter logic
    always @(posedge clk) begin
        if (reset) begin
            counter <= init_ctr;
        end else if (enable) begin
            counter <= counter + 1;
        end
    end
    
    // Counter expansion registers
    always @(posedge clk) begin
        if (reset) begin
            counter_expanded[0] <= 0;
            counter_expanded[1] <= 0;
        end else begin
            counter_expanded[0] <= counter[CTR_WIDTH-1:0];
            counter_expanded[1] <= counter[CTR_WIDTH-1:0];
        end
    end
    
    // Input data and key registration
    always @(posedge clk) begin
        if (reset) begin
            key_reg <= 0;
            data_in_reg <= 0;
        end else begin
            key_reg <= key;
            data_in_reg <= data_in;
        end
    end
    
    // Enable pipeline register
    always @(posedge clk) begin
        if (reset) begin
            enable_pipe <= 0;
        end else begin
            enable_pipe <= enable;
        end
    end
    
    // Encryption operation
    always @(posedge clk) begin
        if (reset) begin
            encrypted_ctr <= 0;
        end else begin
            encrypted_ctr <= {counter_expanded[1], counter_expanded[0]} ^ key_reg;
        end
    end
    
    // Data output logic
    always @(posedge clk) begin
        if (reset) begin
            data_out <= 0;
        end else if (enable_pipe) begin
            data_out <= data_in_reg ^ encrypted_ctr;
        end
    end
    
    // Valid signal generation
    always @(posedge clk) begin
        if (reset) begin
            data_valid <= 0;
        end else begin
            data_valid <= enable_pipe;
        end
    end
endmodule