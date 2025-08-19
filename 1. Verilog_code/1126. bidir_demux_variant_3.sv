//SystemVerilog
module bidir_demux (
    // Bidirectional signals
    inout wire common_io,               // Bidirectional common port
    inout wire [3:0] channel_io,        // Bidirectional channel ports
    
    // Control signals
    input wire [1:0] channel_sel,       // Channel selection
    input wire direction,               // 0: in→out, 1: out→in
    
    // Valid-Ready handshake signals
    input wire valid_i,                 // Input valid signal
    output reg ready_o,                 // Output ready signal
    output reg valid_o,                 // Output valid signal
    input wire ready_i                  // Input ready signal
);
    // Internal signals
    reg [3:0] channel_select;
    reg common_io_en, channel_io_en;
    reg data_transfer_complete;
    
    // One-hot decoder for channel selection
    always @(*) begin
        channel_select = (1'b1 << channel_sel);
    end
    
    // Handshake logic
    always @(*) begin
        // Default values
        ready_o = 1'b0;
        valid_o = 1'b0;
        common_io_en = 1'b0;
        channel_io_en = 1'b0;
        data_transfer_complete = 1'b0;
        
        if (direction) begin  // out→in (channel to common)
            // Ready to receive data from channel when input is valid
            ready_o = valid_i;
            // Signal valid output when data is received and ready_i is high
            valid_o = valid_i & ready_o;
            // Enable common_io when handshake completes
            common_io_en = valid_i & ready_o;
            data_transfer_complete = valid_o & ready_i;
        end else begin  // in→out (common to channel)
            // Ready to receive data when input is valid
            ready_o = valid_i;
            // Signal valid output when data is received
            valid_o = valid_i & ready_o;
            // Enable channel_io when handshake completes
            channel_io_en = valid_i & ready_o;
            data_transfer_complete = valid_o & ready_i;
        end
    end
    
    // Direction control with handshake mechanism
    // Input mode (out→in): common_io receives from selected channel when handshake is complete
    assign common_io = (direction && common_io_en) ? channel_io[channel_sel] : 1'bz;
    
    // Output mode (in→out): only the selected channel drives its output when handshake is complete
    assign channel_io[0] = (!direction && channel_io_en && channel_select[0]) ? common_io : 1'bz;
    assign channel_io[1] = (!direction && channel_io_en && channel_select[1]) ? common_io : 1'bz;
    assign channel_io[2] = (!direction && channel_io_en && channel_select[2]) ? common_io : 1'bz;
    assign channel_io[3] = (!direction && channel_io_en && channel_select[3]) ? common_io : 1'bz;
    
endmodule