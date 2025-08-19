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

    // Internal signals for A to B path
    wire                        is_ack_a_to_b;
    wire                        should_toggle_req_a;
    wire                        req_a_toggle_next;
    wire [WIDTH-1:0]            data_a_reg_next;
    wire [2:0]                  ack_a_sync_next;

    // Internal signals for B to A path
    wire                        is_ack_b_to_a;
    wire                        should_toggle_req_b;
    wire                        req_b_toggle_next;
    wire [WIDTH-1:0]            data_b_reg_next;
    wire [2:0]                  ack_b_sync_next;

    // Internal signals for receive logic A to B
    wire [2:0]                  req_a_sync_next;
    wire                        is_data_b_from_a_load;
    wire                        ack_a_toggle_next;
    wire [WIDTH-1:0]            data_b_from_a_next;

    // Internal signals for receive logic B to A
    wire [2:0]                  req_b_sync_next;
    wire                        is_data_a_from_b_load;
    wire                        ack_b_toggle_next;
    wire [WIDTH-1:0]            data_a_from_b_next;

    // Registers for A to B path
    reg                         req_a_toggle_reg;
    reg [WIDTH-1:0]             data_a_reg;
    reg [2:0]                   ack_a_sync_reg;

    // Registers for B to A path
    reg                         req_b_toggle_reg;
    reg [WIDTH-1:0]             data_b_reg;
    reg [2:0]                   ack_b_sync_reg;

    // Registers for receive logic A to B
    reg [2:0]                   req_a_sync_reg;
    reg                         ack_a_toggle_reg;
    reg [WIDTH-1:0]             data_b_from_a_reg;

    // Registers for receive logic B to A
    reg [2:0]                   req_b_sync_reg;
    reg                         ack_b_toggle_reg;
    reg [WIDTH-1:0]             data_a_from_b_reg;

    // ==========================================
    // Combinational logic for A to B request path (path balanced)
    // ==========================================
    assign is_ack_a_to_b      = (req_a_toggle_reg == ack_a_sync_reg[2]);
    assign should_toggle_req_a = req_a_to_b & is_ack_a_to_b;
    assign req_a_toggle_next  = req_a_toggle_reg ^ should_toggle_req_a;
    assign data_a_reg_next    = should_toggle_req_a ? data_a_to_b : data_a_reg;
    assign ack_a_sync_next    = {ack_a_sync_reg[1:0], ack_a_toggle_reg};

    // ==========================================
    // Combinational logic for B to A request path (path balanced)
    // ==========================================
    assign is_ack_b_to_a      = (req_b_toggle_reg == ack_b_sync_reg[2]);
    assign should_toggle_req_b = req_b_to_a & is_ack_b_to_a;
    assign req_b_toggle_next  = req_b_toggle_reg ^ should_toggle_req_b;
    assign data_b_reg_next    = should_toggle_req_b ? data_b_to_a : data_b_reg;
    assign ack_b_sync_next    = {ack_b_sync_reg[1:0], ack_b_toggle_reg};

    // ==========================================
    // Combinational logic for A to B receive path (path balanced)
    // ==========================================
    assign req_a_sync_next        = {req_a_sync_reg[1:0], req_a_toggle_reg};
    assign is_data_b_from_a_load  = req_a_sync_reg[2] ^ ack_a_toggle_reg;
    assign ack_a_toggle_next      = is_data_b_from_a_load ? req_a_sync_reg[2] : ack_a_toggle_reg;
    assign data_b_from_a_next     = is_data_b_from_a_load ? data_a_reg : data_b_from_a_reg;

    // ==========================================
    // Combinational logic for B to A receive path (path balanced)
    // ==========================================
    assign req_b_sync_next        = {req_b_sync_reg[1:0], req_b_toggle_reg};
    assign is_data_a_from_b_load  = req_b_sync_reg[2] ^ ack_b_toggle_reg;
    assign ack_b_toggle_next      = is_data_a_from_b_load ? req_b_sync_reg[2] : ack_b_toggle_reg;
    assign data_a_from_b_next     = is_data_a_from_b_load ? data_b_reg : data_a_from_b_reg;

    // ==========================================
    // Sequential logic for A to B request path
    // ==========================================
    always @(posedge clk_a or negedge rst_n) begin
        if (!rst_n) begin
            req_a_toggle_reg <= 1'b0;
            data_a_reg       <= {WIDTH{1'b0}};
            ack_a_sync_reg   <= 3'b0;
        end else begin
            req_a_toggle_reg <= req_a_toggle_next;
            data_a_reg       <= data_a_reg_next;
            ack_a_sync_reg   <= ack_a_sync_next;
        end
    end

    // ==========================================
    // Sequential logic for B to A request path
    // ==========================================
    always @(posedge clk_b or negedge rst_n) begin
        if (!rst_n) begin
            req_b_toggle_reg <= 1'b0;
            data_b_reg       <= {WIDTH{1'b0}};
            ack_b_sync_reg   <= 3'b0;
        end else begin
            req_b_toggle_reg <= req_b_toggle_next;
            data_b_reg       <= data_b_reg_next;
            ack_b_sync_reg   <= ack_b_sync_next;
        end
    end

    // ==========================================
    // Sequential logic for A to B receive path
    // ==========================================
    always @(posedge clk_b or negedge rst_n) begin
        if (!rst_n) begin
            req_a_sync_reg     <= 3'b0;
            ack_a_toggle_reg   <= 1'b0;
            data_b_from_a_reg  <= {WIDTH{1'b0}};
        end else begin
            req_a_sync_reg     <= req_a_sync_next;
            ack_a_toggle_reg   <= ack_a_toggle_next;
            data_b_from_a_reg  <= data_b_from_a_next;
        end
    end

    // ==========================================
    // Sequential logic for B to A receive path
    // ==========================================
    always @(posedge clk_a or negedge rst_n) begin
        if (!rst_n) begin
            req_b_sync_reg     <= 3'b0;
            ack_b_toggle_reg   <= 1'b0;
            data_a_from_b_reg  <= {WIDTH{1'b0}};
        end else begin
            req_b_sync_reg     <= req_b_sync_next;
            ack_b_toggle_reg   <= ack_b_toggle_next;
            data_a_from_b_reg  <= data_a_from_b_next;
        end
    end

    // ==========================================
    // Output assignments
    // ==========================================
    assign data_b_from_a = data_b_from_a_reg;
    assign data_a_from_b = data_a_from_b_reg;
    assign ack_a_to_b    = is_ack_a_to_b;
    assign ack_b_to_a    = is_ack_b_to_a;

endmodule