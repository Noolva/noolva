const apps = [
    { key: 'dashbaords', title: 'Dashboards', icon: '/app_icons/dashboards.png' },
    { key: 'users', title: 'Users', icon: '/app_icons/users.png' },
];
const AppGridMenu = ({ onMenuSelect }) => (
    <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 80px)', gap: 12, padding: 12 }}>
        {apps.map(app => (
            <div
                key={app.key}
                style={{
                    display: 'flex',
                    flexDirection: 'column',
                    alignItems: 'center',
                    textAlign: 'center',
                    cursor: 'pointer',
                    transition: 'all 0.2s',
                }}
                onClick={() => handleAppSelect(app.key)}
                onMouseEnter={e => e.currentTarget.style.transform = 'scale(1.05)'}
                onMouseLeave={e => e.currentTarget.style.transform = 'scale(1)'}
            >
                <img src={app.icon} alt={app.title} width={40} height={40} />
                <span style={{ marginTop: 6, fontSize: 12 }}>{app.title}</span>
            </div>
        ))}
    </div>
);
export default AppGridMenu;