//SystemVerilog
module biphase_mark_codec (
    input wire clk,
    input wire rst_n,  // Active low reset
    
    // Input data interface
    input wire data_in,
    input wire data_in_valid,
    output reg data_in_ready,
    
    // Biphase input interface
    input wire biphase_in,
    input wire biphase_in_valid,
    output reg biphase_in_ready,
    
    // Output data interface
    output reg data_out,
    output reg data_out_valid,
    input wire data_out_ready,
    
    // Biphase output interface
    output reg biphase_out,
    output reg biphase_out_valid,
    input wire biphase_out_ready
);
    reg last_bit;
    reg [1:0] bit_timer;
    reg encode_active;
    reg decode_active;
    
    // Encode control logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_in_ready <= 1'b0;
            encode_active <= 1'b0;
        end else begin
            if (!encode_active && data_in_valid) begin
                data_in_ready <= 1'b1;
                encode_active <= 1'b1;
            end else if (encode_active && bit_timer == 2'b11 && biphase_out_ready) begin
                encode_active <= 1'b0;
                data_in_ready <= 1'b0;
            end else begin
                data_in_ready <= 1'b0;
            end
        end
    end
    
    // Decode control logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            biphase_in_ready <= 1'b0;
            decode_active <= 1'b0;
        end else begin
            if (!decode_active && biphase_in_valid) begin
                biphase_in_ready <= 1'b1;
                decode_active <= 1'b1;
            end else if (decode_active && data_out_ready) begin
                decode_active <= 1'b0;
                biphase_in_ready <= 1'b0;
            end else begin
                biphase_in_ready <= 1'b0;
            end
        end
    end
    
    // Bi-phase mark encoding (transition at beginning of each bit,
    // additional transition at mid-bit for a '1')
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            biphase_out <= 1'b0;
            biphase_out_valid <= 1'b0;
            bit_timer <= 2'b00;
            last_bit <= 1'b0;
        end else if (encode_active) begin
            bit_timer <= bit_timer + 1'b1;
            
            if (bit_timer == 2'b00) begin // Start of bit time
                biphase_out <= ~biphase_out; // Always transition
                biphase_out_valid <= 1'b1;
            end else if (bit_timer == 2'b10 && data_in) begin // Mid-bit & data is '1'
                biphase_out <= ~biphase_out; // Additional transition
            end else if (bit_timer == 2'b11) begin
                if (biphase_out_ready) begin
                    biphase_out_valid <= 1'b0;
                end
            end
        end else begin
            bit_timer <= 2'b00;
            biphase_out_valid <= 1'b0;
        end
    end
    
    // Bi-phase mark decoding logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= 1'b0;
            data_out_valid <= 1'b0;
        end else if (decode_active) begin
            // Decoding logic would be implemented here
            // Placeholder for decode implementation
            data_out_valid <= 1'b1;
            
            if (data_out_ready) begin
                data_out_valid <= 1'b0;
            end
        end else begin
            data_out_valid <= 1'b0;
        end
    end
endmodule