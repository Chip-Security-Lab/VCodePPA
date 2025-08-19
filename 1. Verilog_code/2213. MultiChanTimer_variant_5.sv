//SystemVerilog
module MultiChanTimer #(
    parameter CH = 4,  // Number of channels
    parameter DW = 8   // Data width of counters
)(
    input wire clk,                // System clock
    input wire rst_n,              // Active low reset
    input wire [CH-1:0] chan_en,   // Channel enable signals
    output wire [CH-1:0] trig_out  // Output trigger signals
);

    // Pipeline registers
    reg [CH-1:0] chan_en_r1, chan_en_r2;  // Two-stage registered channel enables
    reg [CH-1:0] trig_out_reg;            // Registered trigger outputs
    
    // Pre-compute maximum count value for comparison
    localparam [DW-1:0] MAX_COUNT = {DW{1'b1}};
    
    // Counter registers and comparison flags
    reg [DW-1:0] cnt[0:CH-1];             // Counter registers  
    reg [CH-1:0] near_max_flag;           // Flag for counters approaching max
    wire [CH-1:0] max_cnt_reached;        // Wire for max count detection

    // Register inputs to improve timing
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            chan_en_r1 <= {CH{1'b0}};
            chan_en_r2 <= {CH{1'b0}};
        end else begin
            chan_en_r1 <= chan_en;
            chan_en_r2 <= chan_en_r1;
        end
    end

    // Balance logic paths through channel processing
    genvar i;
    generate 
        for(i=0; i<CH; i=i+1) begin : channel_logic
            // Early detection of counters approaching maximum
            // This breaks the critical path into smaller segments
            always @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    near_max_flag[i] <= 1'b0;
                end else begin
                    // Flag when counter is close to maximum (within 2 counts)
                    near_max_flag[i] <= (cnt[i] >= (MAX_COUNT - 2'd2)) && chan_en_r2[i];
                end
            end
            
            // Counter logic with optimized reset condition
            always @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    cnt[i] <= {DW{1'b0}};
                end else if (max_cnt_reached[i] || !chan_en_r2[i]) begin
                    // Reset counter when max reached or channel disabled
                    cnt[i] <= {DW{1'b0}};
                end else if (chan_en_r2[i]) begin
                    // Only increment when channel is enabled
                    cnt[i] <= cnt[i] + 1'b1;
                end
            end

            // Simplified maximum count detection with early flag optimization
            assign max_cnt_reached[i] = near_max_flag[i] && (cnt[i] == MAX_COUNT);
            
            // Output trigger registration
            always @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    trig_out_reg[i] <= 1'b0;
                end else begin
                    trig_out_reg[i] <= max_cnt_reached[i];
                end
            end
        end
    endgenerate

    // Assign registered outputs
    assign trig_out = trig_out_reg;

endmodule