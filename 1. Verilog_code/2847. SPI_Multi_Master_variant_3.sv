//SystemVerilog
module SPI_Multi_Master #(
    parameter MASTERS = 3
)(
    input  wire                   clk,
    input  wire                   rst_n,
    input  wire [MASTERS-1:0]     req,
    output reg  [MASTERS-1:0]     gnt,
    inout                        sclk,
    inout                        mosi,
    inout                        miso,
    output reg  [MASTERS-1:0]     cs_n
);

    // State encoding
    localparam [1:0] IDLE = 2'd0, ARBITRATION = 2'd1, TRANSFER = 2'd2;

    reg  [1:0]              curr_state, next_state;
    reg  [3:0]              timeout_cnt, next_timeout_cnt;
    reg  [MASTERS-1:0]      last_grant, next_last_grant;

    // Bus signals
    wire [MASTERS-1:0]      master_sclk;
    wire [MASTERS-1:0]      master_mosi;
    wire                    slave_miso;

    // Conflict detection logic
    wire                    bus_active;
    wire                    grant_req_conflict;
    assign bus_active = |(~cs_n);
    assign grant_req_conflict = (|(gnt & req)) & bus_active;

    // Intermediate signals for simplified control
    wire                    any_req;
    wire                    no_bus_active;
    wire                    idle_to_arbit;
    wire                    arb_timeout_expired;
    wire                    all_cs_n_high;

    assign any_req           = |req;
    assign no_bus_active     = ~bus_active;
    assign idle_to_arbit     = (curr_state == IDLE) && any_req && no_bus_active;
    assign arb_timeout_expired = (curr_state == ARBITRATION) && (timeout_cnt > 4'd10);
    assign all_cs_n_high     = (cs_n == {MASTERS{1'b1}});

    // Priority grant logic using hardware comparator structure
    wire [MASTERS-1:0]      req_masked;
    reg  [MASTERS-1:0]      grant_next;
    integer i;
    assign req_masked = req & ~last_grant;

    always @(*) begin : grant_logic
        grant_next = {MASTERS{1'b0}};
        for (i = 0; i < MASTERS; i = i + 1) begin
            if (req[i] && (grant_next == {MASTERS{1'b0}}))
                grant_next[i] = 1'b1;
        end
        gnt = grant_next;
    end

    // Simplified state transition logic with intermediate variables
    always @(*) begin : state_transition
        next_state = curr_state;
        next_timeout_cnt = timeout_cnt;
        next_last_grant = last_grant;

        if (idle_to_arbit) begin
            next_state = ARBITRATION;
            next_last_grant = gnt;
            next_timeout_cnt = 4'd0;
        end else if (curr_state == ARBITRATION) begin
            next_timeout_cnt = timeout_cnt + 4'd1;
            if (arb_timeout_expired) begin
                next_state = TRANSFER;
            end
        end else if (curr_state == TRANSFER) begin
            if (all_cs_n_high) begin
                next_state = IDLE;
            end
        end else begin
            next_state = IDLE;
        end
    end

    // Sequential state update
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            curr_state   <= IDLE;
            timeout_cnt  <= 4'd0;
            last_grant   <= {MASTERS{1'b0}};
            cs_n         <= {MASTERS{1'b1}};
        end else begin
            curr_state   <= next_state;
            timeout_cnt  <= next_timeout_cnt;
            last_grant   <= next_last_grant;
        end
    end

    // Chip select logic
    always @(*) begin : cs_n_logic
        cs_n = ~gnt;
    end

    // Bus driving logic
    assign sclk = (gnt[0]) ? master_sclk[0] :
                  (gnt[1]) ? master_sclk[1] :
                  (gnt[2]) ? master_sclk[2] : 1'bz;

    assign mosi = (gnt[0]) ? master_mosi[0] :
                  (gnt[1]) ? master_mosi[1] :
                  (gnt[2]) ? master_mosi[2] : 1'bz;

    // Placeholder assignments for simulation
    assign master_sclk = {MASTERS{1'b0}};
    assign master_mosi = {MASTERS{1'b0}};
    assign slave_miso  = miso;

endmodule