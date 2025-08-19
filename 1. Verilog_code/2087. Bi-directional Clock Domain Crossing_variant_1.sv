//SystemVerilog
module bidirectional_cdc #(parameter WIDTH = 8) (
    input  wire                 clk_a,
    input  wire                 clk_b,
    input  wire                 rst_n,
    // A to B path
    input  wire [WIDTH-1:0]     data_a_to_b,
    input  wire                 req_a_to_b,
    output wire                 ack_a_to_b,
    output wire [WIDTH-1:0]     data_b_from_a,
    // B to A path
    input  wire [WIDTH-1:0]     data_b_to_a,
    input  wire                 req_b_to_a,
    output wire                 ack_b_to_a,
    output wire [WIDTH-1:0]     data_a_from_b
);

    // ---------------------------------------------------
    // Internal pipeline registers for A->B and B->A paths
    // ---------------------------------------------------

    // A to B Path
    wire                        req_a_to_b_p0;
    wire                        req_a_to_b_p1;
    wire                        req_a_to_b_p2;
    wire [WIDTH-1:0]            data_a_to_b_p0;
    wire [WIDTH-1:0]            data_a_to_b_p1;
    wire                        ack_a_to_b_p0;
    wire                        ack_a_to_b_p1;
    wire                        ack_a_to_b_p2;

    // B to A Path
    wire                        req_b_to_a_p0;
    wire                        req_b_to_a_p1;
    wire                        req_b_to_a_p2;
    wire [WIDTH-1:0]            data_b_to_a_p0;
    wire [WIDTH-1:0]            data_b_to_a_p1;
    wire                        ack_b_to_a_p0;
    wire                        ack_b_to_a_p1;
    wire                        ack_b_to_a_p2;

    // ---------------------------------------------------
    // A->B Pipeline Stages
    // ---------------------------------------------------
    // Stage 0: Request generation (clk_a domain)
    reg                         req_a_toggle_stage0;
    reg [WIDTH-1:0]             data_a_stage0;
    reg                         req_a_toggle_stage1;
    reg [WIDTH-1:0]             data_a_stage1;
    reg [2:0]                   ack_a_pipeline_stage0;
    reg [2:0]                   ack_a_pipeline_stage1;
    reg [2:0]                   ack_a_pipeline_stage2;

    // Stage 1: Request sync (clk_b domain)
    reg [2:0]                   req_a_pipeline_stage0;
    reg [2:0]                   req_a_pipeline_stage1;
    reg [2:0]                   req_a_pipeline_stage2;
    reg                         ack_a_toggle_stage0;
    reg                         ack_a_toggle_stage1;
    reg [WIDTH-1:0]             data_b_from_a_reg;
    
    // ---------------------------------------------------
    // B->A Pipeline Stages
    // ---------------------------------------------------
    // Stage 0: Request generation (clk_b domain)
    reg                         req_b_toggle_stage0;
    reg [WIDTH-1:0]             data_b_stage0;
    reg                         req_b_toggle_stage1;
    reg [WIDTH-1:0]             data_b_stage1;
    reg [2:0]                   ack_b_pipeline_stage0;
    reg [2:0]                   ack_b_pipeline_stage1;
    reg [2:0]                   ack_b_pipeline_stage2;

    // Stage 1: Request sync (clk_a domain)
    reg [2:0]                   req_b_pipeline_stage0;
    reg [2:0]                   req_b_pipeline_stage1;
    reg [2:0]                   req_b_pipeline_stage2;
    reg                         ack_b_toggle_stage0;
    reg                         ack_b_toggle_stage1;
    reg [WIDTH-1:0]             data_a_from_b_reg;

    // ---------------------------------------------------
    // A->B Path: clk_a domain (Pipeline Stage 0)
    // ---------------------------------------------------
    always @(posedge clk_a or negedge rst_n) begin
        if (!rst_n) begin
            req_a_toggle_stage0   <= 1'b0;
            data_a_stage0         <= {WIDTH{1'b0}};
            ack_a_pipeline_stage0 <= 3'b0;
            ack_a_pipeline_stage1 <= 3'b0;
            ack_a_pipeline_stage2 <= 3'b0;
        end else begin
            // Acknowledge pipeline (clk_a domain)
            ack_a_pipeline_stage0 <= {ack_a_pipeline_stage0[1:0], ack_a_toggle_stage1};
            ack_a_pipeline_stage1 <= ack_a_pipeline_stage0;
            ack_a_pipeline_stage2 <= ack_a_pipeline_stage1;

            // Request toggle generation
            if (req_a_to_b && (req_a_toggle_stage0 == ack_a_pipeline_stage2[2])) begin
                req_a_toggle_stage0 <= ~req_a_toggle_stage0;
                data_a_stage0       <= data_a_to_b;
            end
        end
    end

    // ---------------------------------------------------
    // A->B Path: clk_a domain (Pipeline Stage 1)
    // ---------------------------------------------------
    always @(posedge clk_a or negedge rst_n) begin
        if (!rst_n) begin
            req_a_toggle_stage1   <= 1'b0;
            data_a_stage1         <= {WIDTH{1'b0}};
        end else begin
            req_a_toggle_stage1   <= req_a_toggle_stage0;
            data_a_stage1         <= data_a_stage0;
        end
    end

    // ---------------------------------------------------
    // A->B Path: clk_b domain (Pipeline Stage 2)
    // ---------------------------------------------------
    always @(posedge clk_b or negedge rst_n) begin
        if (!rst_n) begin
            req_a_pipeline_stage0 <= 3'b0;
            req_a_pipeline_stage1 <= 3'b0;
            req_a_pipeline_stage2 <= 3'b0;
            ack_a_toggle_stage0   <= 1'b0;
            ack_a_toggle_stage1   <= 1'b0;
            data_b_from_a_reg     <= {WIDTH{1'b0}};
        end else begin
            // Request sync pipeline (clk_b domain)
            req_a_pipeline_stage0 <= {req_a_pipeline_stage0[1:0], req_a_toggle_stage1};
            req_a_pipeline_stage1 <= req_a_pipeline_stage0;
            req_a_pipeline_stage2 <= req_a_pipeline_stage1;

            // Data and acknowledgment pipeline
            if (req_a_pipeline_stage2[2] != ack_a_toggle_stage0) begin
                ack_a_toggle_stage0 <= req_a_pipeline_stage2[2];
                data_b_from_a_reg   <= data_a_stage1;
            end
            ack_a_toggle_stage1 <= ack_a_toggle_stage0;
        end
    end

    // ---------------------------------------------------
    // B->A Path: clk_b domain (Pipeline Stage 0)
    // ---------------------------------------------------
    always @(posedge clk_b or negedge rst_n) begin
        if (!rst_n) begin
            req_b_toggle_stage0   <= 1'b0;
            data_b_stage0         <= {WIDTH{1'b0}};
            ack_b_pipeline_stage0 <= 3'b0;
            ack_b_pipeline_stage1 <= 3'b0;
            ack_b_pipeline_stage2 <= 3'b0;
        end else begin
            // Acknowledge pipeline (clk_b domain)
            ack_b_pipeline_stage0 <= {ack_b_pipeline_stage0[1:0], ack_b_toggle_stage1};
            ack_b_pipeline_stage1 <= ack_b_pipeline_stage0;
            ack_b_pipeline_stage2 <= ack_b_pipeline_stage1;

            // Request toggle generation
            if (req_b_to_a && (req_b_toggle_stage0 == ack_b_pipeline_stage2[2])) begin
                req_b_toggle_stage0 <= ~req_b_toggle_stage0;
                data_b_stage0       <= data_b_to_a;
            end
        end
    end

    // ---------------------------------------------------
    // B->A Path: clk_b domain (Pipeline Stage 1)
    // ---------------------------------------------------
    always @(posedge clk_b or negedge rst_n) begin
        if (!rst_n) begin
            req_b_toggle_stage1   <= 1'b0;
            data_b_stage1         <= {WIDTH{1'b0}};
        end else begin
            req_b_toggle_stage1   <= req_b_toggle_stage0;
            data_b_stage1         <= data_b_stage0;
        end
    end

    // ---------------------------------------------------
    // B->A Path: clk_a domain (Pipeline Stage 2)
    // ---------------------------------------------------
    always @(posedge clk_a or negedge rst_n) begin
        if (!rst_n) begin
            req_b_pipeline_stage0 <= 3'b0;
            req_b_pipeline_stage1 <= 3'b0;
            req_b_pipeline_stage2 <= 3'b0;
            ack_b_toggle_stage0   <= 1'b0;
            ack_b_toggle_stage1   <= 1'b0;
            data_a_from_b_reg     <= {WIDTH{1'b0}};
        end else begin
            // Request sync pipeline (clk_a domain)
            req_b_pipeline_stage0 <= {req_b_pipeline_stage0[1:0], req_b_toggle_stage1};
            req_b_pipeline_stage1 <= req_b_pipeline_stage0;
            req_b_pipeline_stage2 <= req_b_pipeline_stage1;

            // Data and acknowledgment pipeline
            if (req_b_pipeline_stage2[2] != ack_b_toggle_stage0) begin
                ack_b_toggle_stage0 <= req_b_pipeline_stage2[2];
                data_a_from_b_reg   <= data_b_stage1;
            end
            ack_b_toggle_stage1 <= ack_b_toggle_stage0;
        end
    end

    // ---------------------------------------------------
    // Output Signal Assignments
    // ---------------------------------------------------
    assign ack_a_to_b     = (req_a_toggle_stage0 == ack_a_pipeline_stage2[2]);
    assign ack_b_to_a     = (req_b_toggle_stage0 == ack_b_pipeline_stage2[2]);
    assign data_b_from_a  = data_b_from_a_reg;
    assign data_a_from_b  = data_a_from_b_reg;

endmodule