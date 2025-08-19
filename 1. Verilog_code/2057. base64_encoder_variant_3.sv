//SystemVerilog
module base64_encoder_valid_ready (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        data_valid,
    input  wire [7:0]  data_in,
    output wire        data_ready,
    output wire [5:0]  base64_out,
    output wire        base64_valid,
    input  wire        base64_ready
);

    // Stage 1: Input Latch and Buffer Preparation
    reg  [7:0]  data_in_stage1;
    reg         data_valid_stage1;
    reg  [15:0] buffer_stage1;
    reg  [1:0]  out_count_stage1;
    reg         data_ready_stage1;

    // Stage 2: Extract Base64 Output (First Extraction)
    reg  [15:0] buffer_stage2;
    reg  [1:0]  out_count_stage2;
    reg         data_valid_stage2;
    reg  [5:0]  base64_pre_stage2;
    reg         data_ready_stage2;

    // Stage 3: Extract Base64 Output (Second Extraction)
    reg  [15:0] buffer_stage3;
    reg  [1:0]  out_count_stage3;
    reg         data_valid_stage3;
    reg  [5:0]  base64_pre_stage3;
    reg         data_ready_stage3;

    // Stage 4: Extract Base64 Output (Third Extraction)
    reg  [5:0]  base64_out_stage4;
    reg         valid_out_stage4;
    reg         data_ready_stage4;

    // Flush and pipeline control
    reg         flush_stage1, flush_stage2, flush_stage3;

    // Stage 1: Buffer load with valid-ready handshake
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_in_stage1    <= 8'b0;
            data_valid_stage1 <= 1'b0;
            buffer_stage1     <= 16'b0;
            out_count_stage1  <= 2'b00;
            flush_stage1      <= 1'b0;
        end else begin
            if (data_valid && data_ready) begin
                data_in_stage1    <= data_in;
                data_valid_stage1 <= 1'b1;
                buffer_stage1     <= {data_in, 8'b0}; // Load data_in in upper byte
                out_count_stage1  <= 2'b00;
                flush_stage1      <= 1'b0;
            end else if (flush_stage1) begin
                data_valid_stage1 <= 1'b0;
                flush_stage1      <= 1'b0;
            end else if (data_valid_stage1 && data_ready_stage2) begin
                data_valid_stage1 <= 1'b0;
            end
        end
    end

    // Stage 2: First extraction (buffer[15:10]) with valid-ready handshake
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            buffer_stage2      <= 16'b0;
            out_count_stage2   <= 2'b00;
            data_valid_stage2  <= 1'b0;
            base64_pre_stage2  <= 6'b0;
            flush_stage2       <= 1'b0;
        end else begin
            if (data_valid_stage1 && data_ready_stage2) begin
                buffer_stage2     <= buffer_stage1;
                out_count_stage2  <= out_count_stage1 + 1'b1;
                data_valid_stage2 <= 1'b1;
                base64_pre_stage2 <= buffer_stage1[15:10];
                flush_stage2      <= 1'b0;
            end else if (flush_stage2) begin
                data_valid_stage2 <= 1'b0;
                flush_stage2      <= 1'b0;
            end else if (data_valid_stage2 && data_ready_stage3) begin
                data_valid_stage2 <= 1'b0;
            end
        end
    end

    // Stage 3: Second extraction (buffer[9:4]) with valid-ready handshake
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            buffer_stage3      <= 16'b0;
            out_count_stage3   <= 2'b00;
            data_valid_stage3  <= 1'b0;
            base64_pre_stage3  <= 6'b0;
            flush_stage3       <= 1'b0;
        end else begin
            if (data_valid_stage2 && data_ready_stage3) begin
                buffer_stage3     <= buffer_stage2;
                out_count_stage3  <= out_count_stage2 + 1'b1;
                data_valid_stage3 <= 1'b1;
                base64_pre_stage3 <= buffer_stage2[9:4];
                flush_stage3      <= 1'b0;
            end else if (flush_stage3) begin
                data_valid_stage3 <= 1'b0;
                flush_stage3      <= 1'b0;
            end else if (data_valid_stage3 && data_ready_stage4) begin
                data_valid_stage3 <= 1'b0;
            end
        end
    end

    // Stage 4: Third extraction (buffer[3:0] << 2) with valid-ready handshake
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            base64_out_stage4 <= 6'b0;
            valid_out_stage4  <= 1'b0;
        end else begin
            if (data_valid_stage3 && data_ready_stage4) begin
                base64_out_stage4 <= buffer_stage3[3:0] << 2;
                valid_out_stage4  <= 1'b1;
            end else if (valid_out_stage4 && base64_ready) begin
                valid_out_stage4  <= 1'b0;
            end
        end
    end

    // Pipeline ready signal generation for valid-ready handshake
    // Each stage is ready if the next stage is ready or empty
    assign data_ready_stage1  = !data_valid_stage1 || data_ready_stage2;
    assign data_ready_stage2  = !data_valid_stage2 || data_ready_stage3;
    assign data_ready_stage3  = !data_valid_stage3 || data_ready_stage4;
    assign data_ready_stage4  = !valid_out_stage4 || base64_ready;

    assign data_ready = data_ready_stage1;

    // Output selection and valid signal generation with handshake
    reg [1:0] pipeline_sel;
    reg [1:0] pipeline_sel_next;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pipeline_sel <= 2'b00;
        end else if ((data_valid && data_ready) || (base64_valid && base64_ready)) begin
            pipeline_sel <= pipeline_sel_next;
        end
    end

    always @(*) begin
        if (data_valid && data_ready)
            pipeline_sel_next = 2'b00;
        else if (pipeline_sel < 2'b10)
            pipeline_sel_next = pipeline_sel + 1'b1;
        else
            pipeline_sel_next = pipeline_sel;
    end

    reg [5:0] base64_out_mux;
    reg       base64_valid_mux;
    reg       base64_ready_mux;

    always @(*) begin
        case (pipeline_sel)
            2'b00: begin
                base64_out_mux   = base64_pre_stage2;
                base64_valid_mux = data_valid_stage2;
                base64_ready_mux = base64_ready;
            end
            2'b01: begin
                base64_out_mux   = base64_pre_stage3;
                base64_valid_mux = data_valid_stage3;
                base64_ready_mux = base64_ready;
            end
            2'b10: begin
                base64_out_mux   = base64_out_stage4;
                base64_valid_mux = valid_out_stage4;
                base64_ready_mux = base64_ready;
            end
            default: begin
                base64_out_mux   = 6'b0;
                base64_valid_mux = 1'b0;
                base64_ready_mux = 1'b0;
            end
        endcase
    end

    assign base64_out   = base64_out_mux;
    assign base64_valid = base64_valid_mux;

endmodule