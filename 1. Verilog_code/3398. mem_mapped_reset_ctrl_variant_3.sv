//SystemVerilog
module mem_mapped_reset_ctrl (
    input  wire       clk,
    input  wire [3:0] addr,
    input  wire [7:0] data_in,
    input  wire       write_en,
    output reg  [7:0] reset_outputs
);
    // Stage 1: Input registering and buffering
    reg [3:0] addr_stage1;
    reg [7:0] data_stage1;
    reg       write_en_stage1;
    
    // Stage 2: Command decoding
    reg       cmd_write_direct;
    reg       cmd_set_bits;
    reg       cmd_clear_bits;
    reg [7:0] data_stage2;
    
    // Stage 3: Reset control signals
    reg [7:0] set_mask;
    reg [7:0] clear_mask;
    reg [7:0] direct_value;
    reg       update_direct;
    reg       update_masked;
    
    // Stage 1: Register inputs to improve timing
    always @(posedge clk) begin
        addr_stage1     <= addr;
        data_stage1     <= data_in;
        write_en_stage1 <= write_en;
    end
    
    // Stage 2: Decode commands to separate control paths
    always @(posedge clk) begin
        // Default values
        cmd_write_direct <= 1'b0;
        cmd_set_bits     <= 1'b0;
        cmd_clear_bits   <= 1'b0;
        data_stage2      <= data_stage1;
        
        if (write_en_stage1) begin
            case (addr_stage1)
                4'h0: cmd_write_direct <= 1'b1;
                4'h1: cmd_set_bits     <= 1'b1;
                4'h2: cmd_clear_bits   <= 1'b1;
                default: ; // No operation
            endcase
        end
    end
    
    // Stage 3: Prepare control signals for final output update
    always @(posedge clk) begin
        // Default inactive masks
        set_mask     <= 8'h00;
        clear_mask   <= 8'h00;
        direct_value <= 8'h00;
        update_direct <= 1'b0;
        update_masked <= 1'b0;
        
        if (cmd_write_direct) begin
            direct_value  <= data_stage2;
            update_direct <= 1'b1;
        end
        if (cmd_set_bits) begin
            set_mask      <= data_stage2;
            update_masked <= 1'b1;
        end
        if (cmd_clear_bits) begin
            clear_mask    <= data_stage2;
            update_masked <= 1'b1;
        end
    end
    
    // Final stage: Update reset outputs based on control signals
    always @(posedge clk) begin
        if (update_direct) begin
            reset_outputs <= direct_value;
        end
        else if (update_masked) begin
            reset_outputs <= (reset_outputs | set_mask) & ~clear_mask;
        end
    end
    
endmodule