//SystemVerilog
module debounced_reset_detector #(parameter DEBOUNCE_CYCLES = 8)(
    input  wire         clock, 
    input  wire         external_reset_n, 
    input  wire         power_on_reset_n,
    output reg          reset_active, 
    output reg  [1:0]   reset_source
);

    // Stage 1: Input sampling and counter input calculation
    reg [3:0] ext_counter_stage1, por_counter_stage1;
    reg       ext_rstn_stage1, por_rstn_stage1;
    reg       valid_stage1;

    // Stage 2: Carry Lookahead Adder (CLA) generate/propagate
    reg [3:0] ext_a_stage2, ext_b_stage2;
    reg [3:0] por_a_stage2, por_b_stage2;
    reg       ext_rstn_stage2, por_rstn_stage2;
    reg [3:0] ext_counter_stage2, por_counter_stage2;
    reg       valid_stage2;

    reg [3:0] ext_generate_stage2, ext_propagate_stage2;
    reg [3:0] por_generate_stage2, por_propagate_stage2;

    // Stage 3: Carry chain and sum calculation
    reg [3:0] ext_sum_stage3, por_sum_stage3;
    reg [3:0] ext_counter_stage3, por_counter_stage3;
    reg       ext_rstn_stage3, por_rstn_stage3;
    reg       valid_stage3;

    // Stage 4: State update and output calculation
    reg [3:0] ext_counter_reg, por_counter_reg;
    reg       valid_stage4;

    // Pipeline flush logic
    wire flush = 1'b0; // Placeholder, can be connected to a flush/clear signal if needed

    // Stage 1: Sample inputs and compute counter inputs
    always @(posedge clock) begin
        if (flush) begin
            ext_counter_stage1 <= 4'd0;
            por_counter_stage1 <= 4'd0;
            ext_rstn_stage1    <= 1'b1;
            por_rstn_stage1    <= 1'b1;
            valid_stage1       <= 1'b0;
        end else begin
            ext_counter_stage1 <= ext_counter_reg;
            por_counter_stage1 <= por_counter_reg;
            ext_rstn_stage1    <= external_reset_n;
            por_rstn_stage1    <= power_on_reset_n;
            valid_stage1       <= 1'b1;
        end
    end

    // Stage 2: Calculate CLA inputs (generate/propagate)
    always @(posedge clock) begin
        if (flush) begin
            ext_a_stage2         <= 4'd0;
            ext_b_stage2         <= 4'd0;
            por_a_stage2         <= 4'd0;
            por_b_stage2         <= 4'd0;
            ext_rstn_stage2      <= 1'b1;
            por_rstn_stage2      <= 1'b1;
            ext_counter_stage2   <= 4'd0;
            por_counter_stage2   <= 4'd0;
            valid_stage2         <= 1'b0;
            ext_generate_stage2  <= 4'd0;
            ext_propagate_stage2 <= 4'd0;
            por_generate_stage2  <= 4'd0;
            por_propagate_stage2 <= 4'd0;
        end else begin
            ext_a_stage2       <= ext_counter_stage1;
            ext_b_stage2       <= (ext_rstn_stage1 || ext_counter_stage1 == DEBOUNCE_CYCLES) ? 4'd0 : 4'd1;
            por_a_stage2       <= por_counter_stage1;
            por_b_stage2       <= (por_rstn_stage1 || por_counter_stage1 == DEBOUNCE_CYCLES) ? 4'd0 : 4'd1;
            ext_rstn_stage2    <= ext_rstn_stage1;
            por_rstn_stage2    <= por_rstn_stage1;
            ext_counter_stage2 <= ext_counter_stage1;
            por_counter_stage2 <= por_counter_stage1;
            valid_stage2       <= valid_stage1;

            ext_generate_stage2  <= ext_counter_stage1 & ((ext_rstn_stage1 || ext_counter_stage1 == DEBOUNCE_CYCLES) ? 4'd0 : 4'd1);
            ext_propagate_stage2 <= ext_counter_stage1 ^ ((ext_rstn_stage1 || ext_counter_stage1 == DEBOUNCE_CYCLES) ? 4'd0 : 4'd1);
            por_generate_stage2  <= por_counter_stage1 & ((por_rstn_stage1 || por_counter_stage1 == DEBOUNCE_CYCLES) ? 4'd0 : 4'd1);
            por_propagate_stage2 <= por_counter_stage1 ^ ((por_rstn_stage1 || por_counter_stage1 == DEBOUNCE_CYCLES) ? 4'd0 : 4'd1);
        end
    end

    // Stage 3: CLA carry and sum calculation
    always @(posedge clock) begin
        if (flush) begin
            ext_sum_stage3      <= 4'd0;
            por_sum_stage3      <= 4'd0;
            ext_counter_stage3  <= 4'd0;
            por_counter_stage3  <= 4'd0;
            ext_rstn_stage3     <= 1'b1;
            por_rstn_stage3     <= 1'b1;
            valid_stage3        <= 1'b0;
        end else begin
            // ext_counter CLA
            ext_sum_stage3[0] <= ext_propagate_stage2[0] ^ 1'b0;
            ext_sum_stage3[1] <= ext_propagate_stage2[1] ^ (ext_generate_stage2[0] | (ext_propagate_stage2[0] & 1'b0));
            ext_sum_stage3[2] <= ext_propagate_stage2[2] ^ 
                                 (ext_generate_stage2[1] | (ext_propagate_stage2[1] & ext_generate_stage2[0]) | (ext_propagate_stage2[1] & ext_propagate_stage2[0] & 1'b0));
            ext_sum_stage3[3] <= ext_propagate_stage2[3] ^ 
                                 (ext_generate_stage2[2] | (ext_propagate_stage2[2] & ext_generate_stage2[1]) | 
                                 (ext_propagate_stage2[2] & ext_propagate_stage2[1] & ext_generate_stage2[0]) | 
                                 (ext_propagate_stage2[2] & ext_propagate_stage2[1] & ext_propagate_stage2[0] & 1'b0));

            // por_counter CLA
            por_sum_stage3[0] <= por_propagate_stage2[0] ^ 1'b0;
            por_sum_stage3[1] <= por_propagate_stage2[1] ^ (por_generate_stage2[0] | (por_propagate_stage2[0] & 1'b0));
            por_sum_stage3[2] <= por_propagate_stage2[2] ^ 
                                 (por_generate_stage2[1] | (por_propagate_stage2[1] & por_generate_stage2[0]) | (por_propagate_stage2[1] & por_propagate_stage2[0] & 1'b0));
            por_sum_stage3[3] <= por_propagate_stage2[3] ^ 
                                 (por_generate_stage2[2] | (por_propagate_stage2[2] & por_generate_stage2[1]) | 
                                 (por_propagate_stage2[2] & por_propagate_stage2[1] & por_generate_stage2[0]) | 
                                 (por_propagate_stage2[2] & por_propagate_stage2[1] & por_propagate_stage2[0] & 1'b0));

            ext_counter_stage3 <= ext_counter_stage2;
            por_counter_stage3 <= por_counter_stage2;
            ext_rstn_stage3    <= ext_rstn_stage2;
            por_rstn_stage3    <= por_rstn_stage2;
            valid_stage3       <= valid_stage2;
        end
    end

    // Stage 4: Counter register update and output logic
    always @(posedge clock) begin
        if (flush) begin
            ext_counter_reg <= 4'd0;
            por_counter_reg <= 4'd0;
            reset_active    <= 1'b0;
            reset_source    <= 2'b00;
            valid_stage4    <= 1'b0;
        end else begin
            // ext_counter update
            if (ext_rstn_stage3)
                ext_counter_reg <= 4'd0;
            else if (ext_counter_stage3 == DEBOUNCE_CYCLES)
                ext_counter_reg <= ext_counter_stage3;
            else
                ext_counter_reg <= ext_sum_stage3;

            // por_counter update
            if (por_rstn_stage3)
                por_counter_reg <= 4'd0;
            else if (por_counter_stage3 == DEBOUNCE_CYCLES)
                por_counter_reg <= por_counter_stage3;
            else
                por_counter_reg <= por_sum_stage3;

            // Output logic
            reset_active <= (ext_counter_reg == DEBOUNCE_CYCLES) || (por_counter_reg == DEBOUNCE_CYCLES);
            reset_source <= (por_counter_reg == DEBOUNCE_CYCLES) ? 2'b01 :
                            (ext_counter_reg == DEBOUNCE_CYCLES) ? 2'b10 : 2'b00;

            valid_stage4 <= valid_stage3;
        end
    end

endmodule