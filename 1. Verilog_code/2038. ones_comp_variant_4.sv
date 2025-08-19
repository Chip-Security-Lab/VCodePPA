//SystemVerilog
module ones_complement #(parameter WIDTH=8) (
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire [WIDTH-1:0]      data_in,
    output wire [WIDTH-1:0]      data_out
);

    // Pipeline Stage 1: Input Latching
    reg [WIDTH-1:0] data_in_stage1_reg;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            data_in_stage1_reg <= {WIDTH{1'b0}};
        else
            data_in_stage1_reg <= data_in;
    end

    // Pipeline Stage 2: Generate minuend and subtrahend
    reg [WIDTH-1:0] minuend_stage2_reg, subtrahend_stage2_reg;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            minuend_stage2_reg    <= {WIDTH{1'b0}};
            subtrahend_stage2_reg <= {WIDTH{1'b0}};
        end else begin
            minuend_stage2_reg    <= {WIDTH{1'b1}};
            subtrahend_stage2_reg <= data_in_stage1_reg;
        end
    end

    // Pipeline Stage 3: Generate and Propagate borrow signals
    reg [WIDTH-1:0] generate_borrow_stage3_reg, propagate_borrow_stage3_reg;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            generate_borrow_stage3_reg  <= {WIDTH{1'b0}};
            propagate_borrow_stage3_reg <= {WIDTH{1'b0}};
        end else begin
            generate_borrow_stage3_reg  <= ~minuend_stage2_reg & subtrahend_stage2_reg;
            propagate_borrow_stage3_reg <= ~minuend_stage2_reg | subtrahend_stage2_reg;
        end
    end

    // Pipeline Stage 4: Borrow Chain and Output Calculation
    reg [WIDTH:0]   borrow_stage4_reg;
    reg [WIDTH-1:0] data_out_stage4_reg;

    integer j;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            borrow_stage4_reg   <= {(WIDTH+1){1'b0}};
            data_out_stage4_reg <= {WIDTH{1'b0}};
        end else begin
            borrow_stage4_reg[0] = 1'b0;
            for (j = 0; j < WIDTH; j = j + 1) begin
                borrow_stage4_reg[j+1] = generate_borrow_stage3_reg[j] | 
                                         (propagate_borrow_stage3_reg[j] & borrow_stage4_reg[j]);
                data_out_stage4_reg[j] = minuend_stage2_reg[j] ^ subtrahend_stage2_reg[j] ^ borrow_stage4_reg[j];
            end
        end
    end

    // Output Register (Pipeline Stage 5)
    reg [WIDTH-1:0] data_out_reg;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            data_out_reg <= {WIDTH{1'b0}};
        else
            data_out_reg <= data_out_stage4_reg;
    end

    assign data_out = data_out_reg;

endmodule