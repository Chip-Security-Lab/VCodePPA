//SystemVerilog
module binary_to_onehot_demux (
    input  wire        clk,              // Clock input
    input  wire        rst_n,            // Active low reset
    input  wire        data_in,          // Input data
    input  wire [2:0]  binary_addr,      // Binary address
    output reg  [7:0]  one_hot_out       // One-hot outputs with data
);
    // Clock buffer tree
    wire clk_buf1, clk_buf2, clk_buf3;
    
    // Clock buffering for better fanout management
    assign clk_buf1 = clk;
    assign clk_buf2 = clk;
    assign clk_buf3 = clk;
    
    // Pipeline stage 1: Address decoding
    reg [2:0] binary_addr_r;
    reg [7:0] decoder_out;
    reg       data_in_r;
    
    // Buffer registers for high fanout decoder_out
    reg [3:0] decoder_out_buf1;
    reg [3:0] decoder_out_buf2;
    
    // Buffer registers for high fanout data_in_r
    reg       data_in_r_buf1;
    reg       data_in_r_buf2;
    
    // Pipeline stage 2: Data application
    reg [3:0] decoder_out_r_low;
    reg [3:0] decoder_out_r_high;
    reg       data_in_r2_buf1;
    reg       data_in_r2_buf2;
    
    // Internal signal for balanced one-hot output computation
    reg [3:0] one_hot_out_low;
    reg [3:0] one_hot_out_high;
    
    // Stage 1: Register inputs and decode address
    always @(posedge clk_buf1 or negedge rst_n) begin
        if (!rst_n) begin
            binary_addr_r <= 3'b0;
            data_in_r     <= 1'b0;
            decoder_out   <= 8'b0;
        end else begin
            binary_addr_r <= binary_addr;
            data_in_r     <= data_in;
            
            // Binary to one-hot decoding with improved structure
            decoder_out   <= 8'b0;
            decoder_out[binary_addr] <= 1'b1;
        end
    end
    
    // Distribute high fanout signals to buffer registers
    always @(posedge clk_buf2 or negedge rst_n) begin
        if (!rst_n) begin
            decoder_out_buf1 <= 4'b0;
            decoder_out_buf2 <= 4'b0;
            data_in_r_buf1   <= 1'b0;
            data_in_r_buf2   <= 1'b0;
        end else begin
            decoder_out_buf1 <= decoder_out[3:0];
            decoder_out_buf2 <= decoder_out[7:4];
            data_in_r_buf1   <= data_in_r;
            data_in_r_buf2   <= data_in_r;
        end
    end
    
    // Stage 2: Register decoded address and apply data (split for load balancing)
    always @(posedge clk_buf3 or negedge rst_n) begin
        if (!rst_n) begin
            decoder_out_r_low  <= 4'b0;
            decoder_out_r_high <= 4'b0;
            data_in_r2_buf1    <= 1'b0;
            data_in_r2_buf2    <= 1'b0;
        end else begin
            decoder_out_r_low  <= decoder_out_buf1;
            decoder_out_r_high <= decoder_out_buf2;
            data_in_r2_buf1    <= data_in_r_buf1;
            data_in_r2_buf2    <= data_in_r_buf2;
        end
    end
    
    // Final stage: Generate output with reduced logic depth and balanced load
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            one_hot_out_low  <= 4'b0;
            one_hot_out_high <= 4'b0;
            one_hot_out      <= 8'b0;
        end else begin
            // Apply data to outputs through balanced paths
            one_hot_out_low  <= {4{data_in_r2_buf1}} & decoder_out_r_low;
            one_hot_out_high <= {4{data_in_r2_buf2}} & decoder_out_r_high;
            one_hot_out      <= {one_hot_out_high, one_hot_out_low};
        end
    end
endmodule