//SystemVerilog
module bidir_arith_logical_shifter (
    input  wire        clk,          // Clock input
    input  wire        rst_n,        // Active-low reset
    input  wire [31:0] src,          // Source data
    input  wire [4:0]  amount,       // Shift amount
    input  wire        direction,     // 0=left, 1=right
    input  wire        arith_mode,    // 0=logical, 1=arithmetic
    input  wire        s_valid,       // Input valid signal
    output wire        s_ready,       // Input ready signal
    output wire [31:0] result,        // Shift result
    output wire        m_valid,       // Output valid signal
    input  wire        m_ready        // Output ready signal
);
    // Pipeline control signals
    reg stage1_valid, stage2_valid, stage3_valid;
    wire stage1_ready, stage2_ready, stage3_ready;
    
    // Pipeline stage 1: Input registration and shift preparation
    reg [31:0] src_reg;
    reg [4:0]  amount_reg;
    reg        direction_reg;
    reg        arith_mode_reg;
    reg        sign_bit_reg;
    
    // Backpressure handling
    assign s_ready = stage1_ready;
    assign stage1_ready = !stage1_valid || stage2_ready;
    assign stage2_ready = !stage2_valid || stage3_ready;
    assign stage3_ready = !stage3_valid || m_ready;
    
    // Pipeline stage valid signals
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_valid <= 1'b0;
            stage2_valid <= 1'b0;
            stage3_valid <= 1'b0;
        end else begin
            // Stage 1 valid handling
            if (stage1_ready)
                stage1_valid <= s_valid & s_ready;
                
            // Stage 2 valid handling
            if (stage2_ready)
                stage2_valid <= stage1_valid;
                
            // Stage 3 valid handling
            if (stage3_ready)
                stage3_valid <= stage2_valid;
        end
    end
    
    // Pre-computation of sign bit for arithmetic right shift
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            src_reg       <= 32'b0;
            amount_reg    <= 5'b0;
            direction_reg <= 1'b0;
            arith_mode_reg <= 1'b0;
            sign_bit_reg   <= 1'b0;
        end else if (s_valid & s_ready) begin
            src_reg       <= src;
            amount_reg    <= amount;
            direction_reg <= direction;
            arith_mode_reg <= arith_mode;
            sign_bit_reg   <= src[31];  // Pre-compute sign bit for later use
        end
    end
    
    // Pipeline stage 2: Shift operation preparation
    reg [31:0] left_shift_data;
    reg [31:0] right_logical_data;
    reg [31:0] right_arith_data;
    
    // Split shift operations into separate datapaths
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            left_shift_data    <= 32'b0;
            right_logical_data <= 32'b0;
            right_arith_data   <= 32'b0;
        end else if (stage1_valid & stage2_ready) begin
            // Compute all possible shift results in parallel
            left_shift_data    <= src_reg << amount_reg;
            right_logical_data <= src_reg >> amount_reg;
            
            // Arithmetic right shift with sign extension
            // Using more efficient implementation
            right_arith_data <= $signed({(arith_mode_reg & sign_bit_reg), src_reg}) >>> amount_reg;
        end
    end
    
    // Pipeline stage 3: Final multiplexing and output registration
    reg [31:0] result_reg;
    reg        direction_final;
    reg        arith_mode_final;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result_reg <= 32'b0;
            direction_final <= 1'b0;
            arith_mode_final <= 1'b0;
        end else if (stage2_valid & stage3_ready) begin
            direction_final <= direction_reg;
            arith_mode_final <= arith_mode_reg;
            
            // Select the appropriate result based on direction and mode
            case ({direction_reg, arith_mode_reg})
                2'b00: result_reg <= left_shift_data;
                2'b10: result_reg <= right_logical_data;
                2'b11: result_reg <= right_arith_data;
                default: result_reg <= left_shift_data; // Default to left shift for 2'b01
            endcase
        end
    end
    
    // Output assignment
    assign result = result_reg;
    assign m_valid = stage3_valid;

endmodule